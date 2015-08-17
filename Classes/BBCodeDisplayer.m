//
//  BBCodeDisplayer.m
//  Dealabs
//
//  Created by Raphaël Pinto on 04/09/2014.
//  Copyright (c) 2014 HUME Network. All rights reserved.
//

#import "BBCodeDisplayer.h"
#import "Utils.h"
#import "CustomUITextView.h"
#import "Constants.h"



#define kOpeningQuote @"[citer]"
#define kClosingQuote @"[/citer]"
#define kOpeningSpoiler @"[spoiler]"
#define kClosingSpoiler @"[/spoiler]"



@implementation BBCodeDisplayer



@synthesize mDelegate;
@synthesize mSpoilerDelegate;
@synthesize mTextColor;



#pragma mark -
#pragma mark Object Life Cycle Methods



- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        [self setupGestureRecognizer];
    }
    
    return self;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        [self setupGestureRecognizer];
    }
    
    return self;
}


- (void)dealloc
{
    [_mLongPress removeTarget:self action:@selector(didLongPress:)];
    [_mTapGesture removeTarget:self action:@selector(onSpoilerButtonPressed)];
}



#pragma mark -
#pragma mark View Update Methods



- (void)setupWithHTMLString:(NSString*)_HTML
                      width:(float)_Width
              currentHeight:(float)_StartingCurrentHeight
                   delegate:(NSObject<UITextViewDelegate>*)_Delegate
            spoilerDelegate:(NSObject<SpoilerDelegate>*)_SpoilerDelegate
{
    for (UIView* aView in self.subviews)
    {
        [aView removeFromSuperview];
    }
    self.mDelegate = _Delegate;
    self.mSpoilerDelegate = _SpoilerDelegate;
    self.mHTMLString = _HTML;
    self.mCurrentHeight = _StartingCurrentHeight;
    self.mCurrentCharacterIndex = 0;
        
    while (self.mCurrentCharacterIndex < [_HTML length])
    {
        BOOL lNextTagIsQuote = YES;
        NSRange lNextOpenedTagRange = NSMakeRange(NSNotFound, 0);
        
        NSRange lOpeningQuoteRange = [self quoteRangeInString:self.mHTMLString  currentCharIndex:self.mCurrentCharacterIndex];
        
        if (lOpeningQuoteRange.location != NSNotFound)
        {
            lNextOpenedTagRange = lOpeningQuoteRange;
        }
       
        NSRange lOpeningSpoilerRange = [self spoilerRangeInString:self.mHTMLString currentCharIndex:self.mCurrentCharacterIndex];
        if ((lOpeningSpoilerRange.location != NSNotFound) && (lOpeningQuoteRange.location == NSNotFound || lOpeningSpoilerRange.location < lOpeningQuoteRange.location))
        {
            lNextTagIsQuote = NO;
            lNextOpenedTagRange = lOpeningSpoilerRange;
        }
        
        NSString* lText = nil;
        if ([self.mHTMLString length] >= self.mCurrentCharacterIndex)
        {
            if (lNextOpenedTagRange.location != NSNotFound)
            {
                lText = [self.mHTMLString substringWithRange:NSMakeRange(self.mCurrentCharacterIndex, lNextOpenedTagRange.location - self.mCurrentCharacterIndex)];
            }
            else if ([self.mHTMLString length] >= self.mCurrentCharacterIndex)
            {
                lText = [self.mHTMLString substringFromIndex:self.mCurrentCharacterIndex];
            }
        }
        
        
        
        if (lNextOpenedTagRange.location != NSNotFound)
        {
            NSRange lSubRange = NSMakeRange(self.mCurrentCharacterIndex, lNextOpenedTagRange.location - self.mCurrentCharacterIndex);
            
            if ([lText length] > lSubRange.location + lSubRange.length)
            {
                lText =  [self.mHTMLString substringWithRange:lSubRange];
            }
        }
        if ([lText length] > 0)
        {
            [self addTextViewWithString:lText width:_Width];
        }
        
        
        if (lNextTagIsQuote && lOpeningQuoteRange.location != NSNotFound)
        {
            NSString* lText = [self.mHTMLString substringFromIndex:self.mCurrentCharacterIndex];
            
            [self addQuoteWithString:lText width:_Width];
        }
        else if (lOpeningSpoilerRange.location != NSNotFound)
        {
            NSString* lText = [self.mHTMLString substringFromIndex:self.mCurrentCharacterIndex];
            
            [self addSpoilerWithString:lText width:_Width];
        }
    }
    
    self.frame = CGRectMake(self.frame.origin.x,
                            self.frame.origin.y,
                            self.frame.size.width,
                            self.mCurrentHeight + _StartingCurrentHeight);
}


- (void)setupWithHTMLString:(NSString*)_HTML
                      width:(float)_Width
                   delegate:(NSObject<UITextViewDelegate>*)_Delegate
            spoilerDelegate:(NSObject<SpoilerDelegate>*)_SpoilerDelegate
{
    [self setupWithHTMLString:_HTML
                        width:_Width
                currentHeight:0
                     delegate:_Delegate
              spoilerDelegate:_SpoilerDelegate];
}


- (void)addTextViewWithString:(NSString*)_HTMLString
                        width:(float)_Width
{
    NSMutableAttributedString* lAttributedString = [BBCodeDisplayer attributtedStringFromBBCode:_HTMLString replaceSmiley:YES];

    if ([lAttributedString length] == 0)
    {
        self.mCurrentCharacterIndex += [_HTMLString length];
        return;
    }
    
    CustomUITextView* lTextView = [[CustomUITextView alloc] initWithFrame:CGRectMake(5,
                                                                         _mCurrentHeight,
                                                                         _Width - 5,
                                                                         5)];
    
    
    [lTextView setAttributedText:lAttributedString];
    
    if (self.mTextColor)
    {
        lTextView.textColor = self.mTextColor;
    }
    else
    {
        lTextView.textColor = [UIColor blackColor];
    }
    
    lTextView.editable = NO;
    lTextView.contentInset = UIEdgeInsetsZero;
    lTextView.textContainer.lineFragmentPadding = 0;
    lTextView.textContainerInset = UIEdgeInsetsZero;
    lTextView.allowsEditingTextAttributes = NO;
    lTextView.textAlignment = NSTextAlignmentNatural;
    lTextView.backgroundColor = [UIColor clearColor];
    lTextView.clipsToBounds = YES;
    lTextView.scrollEnabled = NO;
    
    if (self.mLinkColor)
    {
        [lTextView setLinkTextAttributes:[NSDictionary dictionaryWithObject:self.mLinkColor forKey:NSForegroundColorAttributeName]];
    }
    else
    {
        [lTextView setLinkTextAttributes:[NSDictionary dictionaryWithObject:kDealabsBlue forKey:NSForegroundColorAttributeName]];
    }
    
    lTextView.delegate = self;
    [lTextView addGestureRecognizer:self.mLongPress];
    
    CGSize size = [lTextView sizeThatFits:CGSizeMake(_Width - 5, FLT_MAX)];
    lTextView.frame = CGRectMake(5,
                                 _mCurrentHeight,
                                 _Width - 5,
                                 size.height);
    
    
    
    [self addSubview:lTextView];

    
    self.mCurrentHeight += size.height;
    self.mCurrentCharacterIndex += [_HTMLString length];
}


- (void)addQuoteWithString:(NSString*)_HTMLString width:(float)_Width
{
    NSString* lQuotedHTML = [self getQuoteSubstringFromHTMLString:_HTMLString];
    
    
    if ([lQuotedHTML length] == 0)
    {
        self.mCurrentCharacterIndex += [kOpeningQuote length];
        return;
    }
    
    BBCodeDisplayer* lQuote = [[BBCodeDisplayer alloc] initWithFrame:CGRectMake(5,
                                                                                _mCurrentHeight + 5,
                                                                                _Width - 10,
                                                                                10)];
    lQuote.mParent = self;
    lQuote.mIsQuote = YES;
    [lQuote setupWithHTMLString:lQuotedHTML
                          width:_Width - 10
                  currentHeight:5
                       delegate:self.mDelegate
                spoilerDelegate:self.mSpoilerDelegate];
    
    lQuote.mDelegate = self.mDelegate;
    lQuote.backgroundColor = [UIColor whiteColor];
    lQuote.clipsToBounds = YES;
    
    
    [self addSubview:lQuote];
    
    UIView* lLeftGrey = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                 0,
                                                                 2,
                                                                 lQuote.frame.size.height)];
    lLeftGrey.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
    lLeftGrey.backgroundColor = [UIColor colorWithRed:197.0f/255.0f green:197.0f/255.0f blue:197.0f/255.0f alpha:1.0f];
    [lQuote addSubview:lLeftGrey];
    
    self.mCurrentHeight = lQuote.frame.origin.y + lQuote.frame.size.height;
    
    self.mCurrentCharacterIndex += [lQuotedHTML length] + [kOpeningQuote length] + [kClosingQuote length];
    self.mHasAlreadyLoaded = YES;
}


- (void)addSpoilerWithString:(NSString*)_HTMLString width:(float)_Width
{
    NSString* lSpoiledHTML = [self getSpoilerSubstringFromHTMLString:_HTMLString];
    
    if ([lSpoiledHTML length] == 0)
    {
        self.mCurrentCharacterIndex += [kOpeningSpoiler length];
        return;
    }
    
    
    BBCodeDisplayer* lSpoiler = [[BBCodeDisplayer alloc] initWithFrame:CGRectMake(5,
                                                                                  _mCurrentHeight + 5,
                                                                                  _Width - 10,
                                                                                  10)];
        
    
    lSpoiler.mDelegate = self.mDelegate;
    lSpoiler.clipsToBounds = YES;
    lSpoiler.mParent = self;
    lSpoiler.mIsSpoiler = YES;
    
    [lSpoiler setupWithHTMLString:lSpoiledHTML
                            width:_Width - 10
                    currentHeight:5
                         delegate:self.mDelegate
                  spoilerDelegate:self.mSpoilerDelegate];
    
    
    CGRect lSpoilerFrame = lSpoiler.frame;
    lSpoilerFrame.size.height = lSpoilerFrame.size.height + 5;
    lSpoiler.frame = lSpoilerFrame;
    lSpoiler.mCurrentHeight += 5;
    
    
    lSpoiler.backgroundColor = [UIColor colorWithRed:238.0f/255.0f green:238.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
    
    
    [self addSubview:lSpoiler];
    
    [lSpoiler addGestureRecognizer:lSpoiler.mTapGesture];
    
    lSpoiler.mIsSpoilerClosed = YES;
    
    // Left Color
    UIView* lLeftGrey = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                 0,
                                                                 2,
                                                                 lSpoiler.frame.size.height)];
    lLeftGrey.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    lLeftGrey.backgroundColor = [UIColor colorWithRed:94.0f/255.0f green:94.0f/255.0f blue:94.0f/255.0f alpha:1.0f];
    [lSpoiler addSubview:lLeftGrey];
    
    
    
    
    
    
    lSpoiler.frame = CGRectMake(lSpoiler.frame.origin.x,
                                lSpoiler.frame.origin.y,
                                lSpoiler.frame.size.width,
                                25);
    self.mCurrentHeight = lSpoiler.frame.origin.y + lSpoiler.frame.size.height + 5;
    
    self.mCurrentCharacterIndex += [lSpoiledHTML length] + [kOpeningSpoiler length] + [kClosingSpoiler length];
}



#pragma mark -
#pragma mark BBCode Dicsplayer Delegate Methods



- (NSRange)quoteRangeInString:(NSString*)_String currentCharIndex:(NSInteger)_CurrentCharIndex
{
    if ([_String length] < _CurrentCharIndex)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    
    return [_String rangeOfString:kOpeningQuote options:NSCaseInsensitiveSearch range:NSMakeRange(_CurrentCharIndex, [_String length] - _CurrentCharIndex)];
}


- (NSRange)spoilerRangeInString:(NSString*)_String currentCharIndex:(NSInteger)_CurrentCharIndex
{
    if ([_String length] < _CurrentCharIndex)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    
    return [_String rangeOfString:kOpeningSpoiler options:NSCaseInsensitiveSearch range:NSMakeRange(_CurrentCharIndex, [_String length] - _CurrentCharIndex)];
}


- (NSRange)endingQuoteRangeInString:(NSString*)_String currentCharIndex:(NSInteger)_CurrentCharIndex
{
    if ([_String length] < _CurrentCharIndex)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    
    return [_String rangeOfString:kClosingQuote options:NSCaseInsensitiveSearch range:NSMakeRange(_CurrentCharIndex, [_String length] - _CurrentCharIndex)];
}


- (NSRange)endingSpoilerRangeInString:(NSString*)_String currentCharIndex:(NSInteger)_CurrentCharIndex
{
    if ([_String length] < _CurrentCharIndex)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    
    return [_String rangeOfString:kClosingSpoiler options:NSCaseInsensitiveSearch range:NSMakeRange(_CurrentCharIndex, [_String length] - _CurrentCharIndex)];
}



#pragma mark -
#pragma mark Text Compute Methods



+ (void)replaceBBCodeOpeningTag:(NSString*)_OpeningTag
                     closingTag:(NSString*)_CLosingTag
               attributedString:(NSMutableAttributedString*)_AttributedString
                      attribute:(NSString*)_AttributeName
                          value:(id)_AttributeValue
{
    NSString* lRegExOpenningTag = [_OpeningTag stringByReplacingOccurrencesOfString:@"[" withString:@"\\["];
    lRegExOpenningTag = [lRegExOpenningTag stringByReplacingOccurrencesOfString:@"]" withString:@"\\]"];
    int lRemovedCharacters = 0;
    
    NSString* lRegExClosingTag = [_CLosingTag stringByReplacingOccurrencesOfString:@"[" withString:@"\\["];
    lRegExClosingTag = [lRegExClosingTag stringByReplacingOccurrencesOfString:@"]" withString:@"\\]"];
    lRegExClosingTag = [lRegExClosingTag stringByReplacingOccurrencesOfString:@"/" withString:@"\\/"];
    
    
    NSRegularExpression* lRegex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"%@(.*)%@", lRegExOpenningTag, lRegExClosingTag]options:0 error:NULL];
    NSArray* lMatches = [lRegex matchesInString:_AttributedString.string options:0 range:NSMakeRange(0, [_AttributedString.string length])];
    
    
    for (NSTextCheckingResult* aTextCheckingResult in lMatches)
    {
        NSString* lSubString = [_AttributedString.string substringWithRange:NSMakeRange([aTextCheckingResult range].location - lRemovedCharacters, [aTextCheckingResult range].length)];
        lSubString = [lSubString substringWithRange:NSMakeRange([_OpeningTag length], [lSubString length] - [_OpeningTag length] - [_CLosingTag length])];
        
        [_AttributedString replaceCharactersInRange:NSMakeRange([aTextCheckingResult range].location - lRemovedCharacters, [aTextCheckingResult range].length) withString:lSubString];
        [_AttributedString addAttribute:_AttributeName value:_AttributeValue range:NSMakeRange([aTextCheckingResult range].location - lRemovedCharacters, [lSubString length])];
        
        lRemovedCharacters = [aTextCheckingResult range].length - [lSubString length];
    }
}


+ (void)replaceBBCodeLinkWithAttributedString:(NSMutableAttributedString*)_AttributedString
{
    NSRegularExpression* lRegex = [NSRegularExpression regularExpressionWithPattern:@"\\[url=(.*)\\](.*)\\[\\/url\\]" options:0 error:NULL];
    NSArray* lMatches = [lRegex matchesInString:_AttributedString.string options:0 range:NSMakeRange(0, [_AttributedString.string length])];
    int lRemovedCharacters = 0;
    
    for (NSTextCheckingResult* aTextCheckingResult in lMatches)
    {
        NSString* lSubString = [_AttributedString.string substringWithRange:NSMakeRange([aTextCheckingResult range].location - lRemovedCharacters, [aTextCheckingResult range].length)];

        
        // Extract the full url
        NSRegularExpression* lRegexURL = [NSRegularExpression regularExpressionWithPattern:@"\\[url=(.*?)\\]" options:0 error:NULL];
        NSTextCheckingResult* lMatch2 = [lRegexURL firstMatchInString:lSubString options:0 range:NSMakeRange(0, [lSubString length])];
        NSRange lURLRange = NSMakeRange([lMatch2 range].location + 5, [lMatch2 range].length - ([lMatch2 range].location + 6)); // 6 is the [url=] lenght; 5 is the [url= lenght
        NSString* lURL = [lSubString substringWithRange:lURLRange];
    
        
        // Extract the visible URL
        NSRange lVisibleURLRange = NSMakeRange([aTextCheckingResult range].location + [lMatch2 range].length - lRemovedCharacters, [aTextCheckingResult range].length - ([lMatch2 range].length + 6)); // 6 is the lenght of [/url]
        NSString* lVisibleURL = [_AttributedString.string substringWithRange:lVisibleURLRange];
        
        
        // Replace the BBCode Link by the attributted string
        [_AttributedString replaceCharactersInRange:NSMakeRange([aTextCheckingResult range].location - lRemovedCharacters, [aTextCheckingResult range].length) withString:lVisibleURL];
        [_AttributedString addAttribute:NSLinkAttributeName value:lURL range:NSMakeRange([aTextCheckingResult range].location - lRemovedCharacters, [lVisibleURL length])];
        
        lRemovedCharacters = [aTextCheckingResult range].length - [lVisibleURL length];
    }
}


+ (void)replaceImageOpeningTag:(NSString*)_OpeningTag
                    closingTag:(NSString*)_CLosingTag
              attributedString:(NSMutableAttributedString*)_AttributedString
{
    NSRegularExpression* lRegex = [NSRegularExpression regularExpressionWithPattern:@"\\[img\\]([A-Za-z0-9_.-~]{1,})\\[\\/img\\]" options:0 error:NULL];
    NSArray* lMatches = [lRegex matchesInString:_AttributedString.string options:0 range:NSMakeRange(0, [_AttributedString.string length])];
    int lRemovedCharacters = 0;
    
    
    for (NSTextCheckingResult* aTextCheckingResult in lMatches)
    {
        NSString* lSubString = [_AttributedString.string substringWithRange:NSMakeRange([aTextCheckingResult range].location + [_OpeningTag length] - lRemovedCharacters, [aTextCheckingResult range].length - [_OpeningTag length] - [_CLosingTag length])];
        
        [_AttributedString replaceCharactersInRange:NSMakeRange([aTextCheckingResult range].location - lRemovedCharacters, [aTextCheckingResult range].length) withString:lSubString];
        [_AttributedString addAttribute:NSLinkAttributeName value:[NSString stringWithFormat:@"IMAGE_COMMENT_FULLSCREEN_%@", lSubString] range:NSMakeRange([aTextCheckingResult range].location - lRemovedCharacters, [lSubString length])];
        
        lRemovedCharacters = [aTextCheckingResult range].length - [lSubString length];
    }
}


+ (NSMutableAttributedString*)attributtedStringFromBBCode:(NSString*)_BBCodeString replaceSmiley:(BOOL)_ReplaceSmiley
{
    NSMutableAttributedString* AttributedString = [[NSMutableAttributedString alloc] initWithString:_BBCodeString];
   
    
    [self replaceBBCodeOpeningTag:@"[s]"
                       closingTag:@"[/s]"
                 attributedString:AttributedString
                        attribute:NSStrikethroughStyleAttributeName
                            value:[NSNumber numberWithInt:1]];
    
    [self replaceBBCodeOpeningTag:@"[b]"
                       closingTag:@"[/b]"
                 attributedString:AttributedString
                        attribute:NSFontAttributeName
                            value:[UIFont fontWithName:@"Helvetica-Bold" size:12]];
    
    [self replaceBBCodeOpeningTag:@"[i]"
                       closingTag:@"[/i]"
                 attributedString:AttributedString
                        attribute:NSFontAttributeName
                            value:[UIFont fontWithName:@"HelveticaNeue-Italic" size:13]];
    
    [self replaceBBCodeOpeningTag:@"[u]"
                       closingTag:@"[/u]"
                 attributedString:AttributedString
                        attribute:NSUnderlineStyleAttributeName
                            value:[NSNumber numberWithInt:1]];
    
    [BBCodeDisplayer replaceBBCodeLinkWithAttributedString:AttributedString];
    
    [BBCodeDisplayer replaceImageOpeningTag:@"[img]"
                                 closingTag:@"[/img]"
                           attributedString:AttributedString];
    
    
    if (_ReplaceSmiley)
    {
        [BBCodeDisplayer replaceSmileyWithString:@"':)" smileyImage:@"evil.png" inMutableString:AttributedString];
        [BBCodeDisplayer replaceSmileyWithString:@":o" smileyImage:@"agape.png" inMutableString:AttributedString];
        [BBCodeDisplayer replaceSmileyWithString:@"xD" smileyImage:@"big_grin_squint.png" inMutableString:AttributedString];
        [BBCodeDisplayer replaceSmileyWithString:@":(" smileyImage:@"frown.png" inMutableString:AttributedString];
        [BBCodeDisplayer replaceSmileyWithString:@":3" smileyImage:@"inlove.png" inMutableString:AttributedString];
        [BBCodeDisplayer replaceSmileyWithString:@"|D" smileyImage:@"nerdy.png" inMutableString:AttributedString];
        [BBCodeDisplayer replaceSmileyWithString:@"|o" smileyImage:@"redface.png" inMutableString:AttributedString];
        [BBCodeDisplayer replaceSmileyWithString:@":S" smileyImage:@"sick.png" inMutableString:AttributedString];
        [BBCodeDisplayer replaceSmileyWithString:@":P" smileyImage:@"silly.png" inMutableString:AttributedString];
        [BBCodeDisplayer replaceSmileyWithString:@":)" smileyImage:@"smile.png" inMutableString:AttributedString];
        [BBCodeDisplayer replaceSmileyWithString:@"xS" smileyImage:@"sour.png" inMutableString:AttributedString];
        [BBCodeDisplayer replaceSmileyWithString:@"-_-'" smileyImage:@"stress.png" inMutableString:AttributedString];
        [BBCodeDisplayer replaceSmileyWithString:@"B)" smileyImage:@"sunglasses_3.png" inMutableString:AttributedString];
        [BBCodeDisplayer replaceSmileyWithString:@";)" smileyImage:@"wink.png" inMutableString:AttributedString];
        [BBCodeDisplayer replaceSmileyWithString:@":|" smileyImage:@"zipped.png" inMutableString:AttributedString];
        [BBCodeDisplayer replaceSmileyWithString:@":D" smileyImage:@"rire.png" inMutableString:AttributedString];
        [BBCodeDisplayer replaceSmileyWithString:@"^^" smileyImage:@"cool.png" inMutableString:AttributedString];
        [BBCodeDisplayer replaceSmileyWithString:@":'(" smileyImage:@"crying.png" inMutableString:AttributedString];
    }
    
    [BBCodeDisplayer replaceSmileyWithString:@"[Img_Picto]" smileyImage:@"commentPicIcon.png" inMutableString:AttributedString];
        
    return AttributedString;
}


+ (void)replaceSmileyWithString:(NSString*)_SmileyString
                    smileyImage:(NSString*)_SmileyImage
                inMutableString:(NSMutableAttributedString*)_MutableString
{
    [self replaceOneKindOfSmiley:[NSString stringWithFormat:@" %@", _SmileyString]
                           range:NSMakeRange(1,[_SmileyString length])
                     smileyImage:_SmileyImage
                 inMutableString:_MutableString];
    [self replaceOneKindOfSmiley:[NSString stringWithFormat:@"%@ ", _SmileyString]
                           range:NSMakeRange(0,[_SmileyString length])
                     smileyImage:_SmileyImage
                 inMutableString:_MutableString];
}


+ (void)replaceOneKindOfSmiley:(NSString*)_SmileyString
                         range:(NSRange)_Range
                   smileyImage:(NSString*)_SmileyImage
               inMutableString:(NSMutableAttributedString*)_MutableString
{
    if ([_MutableString.string length] == 0)
    {
        return;
    }
    
    
    NSRange lSmileyRange = [_MutableString.string rangeOfString:_SmileyString];
    
    while (lSmileyRange.location != NSNotFound)
    {
        lSmileyRange = NSMakeRange(lSmileyRange.location + _Range.location, _Range.length);
        
        NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
        textAttachment.image = [UIImage imageNamed:_SmileyImage];
        /* textAttachment.bounds = CGRectMake(textAttachment.bounds.origin.x,
         textAttachment.bounds.origin.y,
         13, 13);*/
        NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:textAttachment];
        
        [_MutableString replaceCharactersInRange:lSmileyRange withAttributedString:attrStringWithImage];
        
        lSmileyRange = [_MutableString.string rangeOfString:_SmileyString];
    }
}



#pragma mark -
#pragma mark Data Management Methods



- (void)setupGestureRecognizer
{
    UILongPressGestureRecognizer* lGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPress:)];
    self.mLongPress = lGesture;
    [self addGestureRecognizer:self.mLongPress];
    
    UITapGestureRecognizer* lTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSpoilerButtonPressed)];
    self.mTapGesture = lTapGesture;
}


- (NSString*)getSpoilerSubstringFromHTMLString:(NSString*)_HTMLString
{
    int lNewOpenedTag = 0;
    unsigned long lCurrentCharLocation = 0;
    
    
    while (lCurrentCharLocation < [_HTMLString length])
    {
        NSRange lOpenTagRange = [self spoilerRangeInString:_HTMLString currentCharIndex:lCurrentCharLocation];
        NSRange lCloseTagRange = [self endingSpoilerRangeInString:_HTMLString currentCharIndex:lCurrentCharLocation];
        
        
        // Open Tag reached
        if (lOpenTagRange.location < lCloseTagRange.location)
        {
            lNewOpenedTag++;
            
            lCurrentCharLocation = lOpenTagRange.location + lOpenTagRange.length;
        }
        // Close Tag reached
        else
        {
            // No other Tag previously opened
            if (lNewOpenedTag <= 1 && lCloseTagRange.location != NSNotFound)
            {
                return [[_HTMLString substringFromIndex:[kOpeningSpoiler length]] substringToIndex:lCloseTagRange.location - [kOpeningSpoiler length]];
            }
            // Another open tag has been opened
            else
            {
                lNewOpenedTag--;
                
                lCurrentCharLocation = lCloseTagRange.location + lCloseTagRange.length;
            }
        }
    }
    
    return nil;
}


- (NSString*)getQuoteSubstringFromHTMLString:(NSString*)_HTMLString
{
    int lNewOpenedTag = 0;
    unsigned long lCurrentCharLocation = 0;
    
    
    while (lCurrentCharLocation < [_HTMLString length])
    {
        NSRange lOpenTagRange = [self quoteRangeInString:_HTMLString currentCharIndex:lCurrentCharLocation];
        NSRange lCloseTagRange = [self endingQuoteRangeInString:_HTMLString currentCharIndex:lCurrentCharLocation];
        
        
        // Open Tag reached
        if (lOpenTagRange.location < lCloseTagRange.location)
        {
            lNewOpenedTag++;
            
            lCurrentCharLocation = lOpenTagRange.location + lOpenTagRange.length;
        }
        // Close Tag reached
        else
        {
            // No other Tag previously opened
            if (lNewOpenedTag <= 1 && lCloseTagRange.location != NSNotFound)
            {
                return [[_HTMLString substringFromIndex:[kOpeningQuote length]] substringToIndex:lCloseTagRange.location - [kOpeningQuote length]];
            }
            // Another open tag has been opened
            else
            {
                lNewOpenedTag--;
                
                lCurrentCharLocation = lCloseTagRange.location + lCloseTagRange.length;
            }
        }
    }
    
    return nil;
}


+ (NSArray*)getSubstringForOpeningTag:(NSString*)_Tag
                          toEndingTag:(NSString*)_EndingTag
                       fromHTMLString:(NSString*)_HTMLString
                  currentCharLocation:(unsigned long)_CurrentCharLocation
{
    int lNewOpenedTag = 0;
    NSRange lOpenTagRange = NSMakeRange(NSNotFound, 0);
    
    
    while (_CurrentCharLocation < [_HTMLString length])
    {
        NSRange lOpenTagRangeTmp = [_HTMLString rangeOfString:_Tag
                                                      options:NSCaseInsensitiveSearch
                                                        range:NSMakeRange(_CurrentCharLocation, [_HTMLString length] - _CurrentCharLocation)];
        
        NSRange lCloseTagRange = [_HTMLString rangeOfString:_EndingTag
                                                    options:NSCaseInsensitiveSearch
                                                      range:NSMakeRange(_CurrentCharLocation, [_HTMLString length] - _CurrentCharLocation)];
        
        // Open Tag reached
        if (lOpenTagRangeTmp.location != NSNotFound && lCloseTagRange.location != NSNotFound && lOpenTagRangeTmp.location < lCloseTagRange.location)
        {
            if (lOpenTagRange.location == NSNotFound)
            {
                lOpenTagRange = lOpenTagRangeTmp;
            }
            
            lNewOpenedTag++;
            
            _CurrentCharLocation = lOpenTagRangeTmp.location + lOpenTagRangeTmp.length;
        }
        // Close Tag reached
        else if (lCloseTagRange.location != NSNotFound)
        {
            // No other Tag previously opened
            if (lNewOpenedTag <= 1 && lCloseTagRange.location != NSNotFound && lOpenTagRange.location != NSNotFound)
            {
                NSString* lSubString = [[_HTMLString substringFromIndex:lOpenTagRange.location + lOpenTagRange.length] substringToIndex:lCloseTagRange.location - lOpenTagRange.location - lOpenTagRange.length];
                
                
                NSValue* lRangeValue = [NSValue valueWithRange:NSMakeRange(lOpenTagRange.location + lOpenTagRange.length, lCloseTagRange.location - lOpenTagRange.location - lOpenTagRange.length)];
                return [NSArray arrayWithObjects:lSubString, lRangeValue, nil];
            }
            // Another open tag has been opened
            else
            {
                lNewOpenedTag--;
                
                _CurrentCharLocation = lCloseTagRange.location + lCloseTagRange.length;
            }
        }
        else
        {
            return [NSArray arrayWithObjects:@"", [NSValue valueWithRange:NSMakeRange(NSNotFound, 0)], nil];
        }
    }
    
    return [NSArray arrayWithObjects:@"", [NSValue valueWithRange:NSMakeRange(NSNotFound, 0)], nil];
}


+ (NSMutableDictionary*)getSubstringForLinkOpeningTag:(NSString*)_Tag
                                          toEndingTag:(NSString*)_EndingTag
                                       fromHTMLString:(NSString*)_HTMLString
                                  currentCharLocation:(unsigned long)_CurrentCharLocation
{
    int lNewOpenedTag = 0;
    NSRange lOpenTagRange = NSMakeRange(NSNotFound, 0);
    
    
    NSString* lLink = nil;
    NSRange lURLRange = NSMakeRange(NSNotFound, 0);
    
    
    while (_CurrentCharLocation < [_HTMLString length])
    {
        NSRange lOpenTagRangeTmp = [_HTMLString rangeOfString:_Tag
                                                      options:NSCaseInsensitiveSearch
                                                        range:NSMakeRange(_CurrentCharLocation, [_HTMLString length] - _CurrentCharLocation)];
        
        
        NSRange lCloseTagRange = [_HTMLString rangeOfString:_EndingTag
                                                    options:NSCaseInsensitiveSearch
                                                      range:NSMakeRange(_CurrentCharLocation, [_HTMLString length] - _CurrentCharLocation)];
        
        
        // Open Tag reached
        if (lOpenTagRangeTmp.location != NSNotFound && lCloseTagRange.location != NSNotFound && lOpenTagRangeTmp.location < lCloseTagRange.location)
        {
            if (lOpenTagRange.location == NSNotFound)
            {
                lOpenTagRange = lOpenTagRangeTmp;
                
                lURLRange = [_HTMLString rangeOfString:@"]"
                                               options:NSCaseInsensitiveSearch
                                                 range:NSMakeRange(lOpenTagRangeTmp.location + lOpenTagRangeTmp.length, [_HTMLString length] - lOpenTagRangeTmp.location - lOpenTagRangeTmp.length)];
                
                if ([_HTMLString length] > lOpenTagRangeTmp.location + lOpenTagRangeTmp.length + lURLRange.location - lOpenTagRangeTmp.location - lOpenTagRangeTmp.length)
                {
                    lLink = [_HTMLString substringWithRange:NSMakeRange(lOpenTagRangeTmp.location + lOpenTagRangeTmp.length, lURLRange.location - lOpenTagRangeTmp.location - lOpenTagRangeTmp.length)];
                }
                
                
                NSRange lBuggedOpenTagRange = [lLink rangeOfString:_Tag
                                                           options:NSCaseInsensitiveSearch
                                                             range:NSMakeRange(0, [lLink length])];
         
                if (lBuggedOpenTagRange.location != NSNotFound)
                {
                    lOpenTagRange = NSMakeRange(lOpenTagRangeTmp.location + lOpenTagRangeTmp.length + lBuggedOpenTagRange.location, lBuggedOpenTagRange.length);
                    
                    lURLRange = [_HTMLString rangeOfString:@"]"
                                                   options:NSCaseInsensitiveSearch
                                                     range:NSMakeRange(lOpenTagRange.location, [_HTMLString length] - lOpenTagRange.location - lOpenTagRange.length)];
               
                    
                    if ([_HTMLString length] > lOpenTagRange.location + lOpenTagRange.length + lURLRange.location - lOpenTagRange.location - lOpenTagRange.length)
                    {
                        lLink = [_HTMLString substringWithRange:NSMakeRange(lOpenTagRange.location + lOpenTagRange.length, lURLRange.location - lOpenTagRange.location - lOpenTagRange.length)];
                    }
                    
                    lNewOpenedTag++;
                    
                    _CurrentCharLocation = lURLRange.location + lURLRange.length;
                    
                    continue;
                }
            }
            
            lNewOpenedTag++;
            
            _CurrentCharLocation = lOpenTagRangeTmp.location + lOpenTagRangeTmp.length;
        }
        // Close Tag reached
        else if (lCloseTagRange.location != NSNotFound)
        {
            // No other Tag previously opened
            if (lNewOpenedTag <= 1 && lCloseTagRange.location != NSNotFound && lOpenTagRange.location != NSNotFound)
            {
                NSRange lDisplayedStringRange = NSMakeRange(lURLRange.location + lURLRange.length, lCloseTagRange.location - lURLRange.location - lURLRange.length);
                
                if ([_HTMLString length] > lDisplayedStringRange.location && lDisplayedStringRange.length != FLT_MAX)
                {
                    NSString* lSubStr = [_HTMLString substringFromIndex:lDisplayedStringRange.location];
                    
                    if ([lSubStr length] > lDisplayedStringRange.length)
                    {
                        NSString* lSubString = [[_HTMLString substringFromIndex:lDisplayedStringRange.location] substringToIndex:lDisplayedStringRange.length];
                        
                        NSValue* lRangeValue = [NSValue valueWithRange:lDisplayedStringRange];
                        NSValue* lbbcodeTotalRange = [NSValue valueWithRange:NSMakeRange(lOpenTagRange.location, lCloseTagRange.location + lCloseTagRange.length - lOpenTagRange.location)];
                        
                        
                        NSMutableDictionary* lReturnValue = [NSMutableDictionary dictionary];
                        if (lLink)
                        {
                            [lReturnValue setObject:lLink forKey:@"link"];
                        }
                        [lReturnValue setObject:lRangeValue forKey:@"displayedStringRange"];
                        [lReturnValue setObject:lSubString forKey:@"displayedString"];
                        [lReturnValue setObject:lbbcodeTotalRange forKey:@"bbcodeTotalRange"];
                        
                        return lReturnValue;
                    }
                    else
                    {
                        _CurrentCharLocation = lCloseTagRange.location + lCloseTagRange.length;
                    }
                }
                else 
                {
                    _CurrentCharLocation = lCloseTagRange.location + lCloseTagRange.length;
                }
            }
            // Another open tag has been opened
            else
            {
                lNewOpenedTag--;
                _CurrentCharLocation = lCloseTagRange.location + lCloseTagRange.length;
            }
        }
        else
        {
            return nil;
        }
    }
    
    return nil;
}


- (void)updateSize:(float)_AdjustVal forSubView:(UIView*)_SubView
{
    self.mCurrentHeight += _AdjustVal;
    
    for (UIView* aView in self.subviews)
    {
        if ([self.subviews indexOfObject:aView] > [self.subviews indexOfObject:_SubView])
        {
            if (aView.frame.size.width == 2)
            {
                aView.frame = CGRectMake(aView.frame.origin.x,
                                         aView.frame.origin.y,
                                         aView.frame.size.width,
                                         aView.frame.size.height + _AdjustVal);
            }
            else
            {
                aView.frame = CGRectMake(aView.frame.origin.x,
                                         aView.frame.origin.y + _AdjustVal,
                                         aView.frame.size.width,
                                         aView.frame.size.height);
            }
        }
    }
    
    self.frame = CGRectMake(self.frame.origin.x,
                            self.frame.origin.y,
                            self.frame.size.width,
                            self.frame.size.height + _AdjustVal);
    
    
    if (self.mParent)
    {
        [self.mParent updateSize:_AdjustVal forSubView:self];
    }
    else
    {
        if (mSpoilerDelegate && [mSpoilerDelegate respondsToSelector:@selector(BBCodeSpoilerPressed:)])
        {
            [mSpoilerDelegate BBCodeSpoilerPressed:self];
        }
    }
}


+ (float)calculateBBCodeHeightForBBCodeText:(NSString*)_BBCodeText maxWidth:(float)_MaxWidth
{
    BBCodeDisplayer* lBBCodeDisplay = [[BBCodeDisplayer alloc] init];
    [lBBCodeDisplay setupWithHTMLString:_BBCodeText
                                  width:_MaxWidth
                               delegate:nil
                        spoilerDelegate:nil];
    return lBBCodeDisplay.mCurrentHeight;
}



#pragma mark -
#pragma mark User Interaction Methods



- (IBAction)onSpoilerButtonPressed
{
    self.mIsSpoilerClosed = !self.mIsSpoilerClosed;
    
    if (!self.mIsSpoilerClosed)
    {
        self.frame = CGRectMake(self.frame.origin.x,
                                self.frame.origin.y,
                                self.frame.size.width,
                                self.mCurrentHeight);
        
        [self.mParent updateSize:self.mCurrentHeight - 25 forSubView:self];
    }
    else
    {
        self.frame = CGRectMake(self.frame.origin.x,
                                self.frame.origin.y,
                                self.frame.size.width,
                                25);
        
        [self.mParent updateSize:- (self.mCurrentHeight - 25) forSubView:self];
    }
}


- (IBAction)didLongPress:(UIGestureRecognizer*)_Gesture
{
    if(_Gesture.state == UIGestureRecognizerStateBegan)
    {
        if (self.mParent)
        {
            [self.mParent didLongPress:_Gesture];
        }
        else if ([self.mSpoilerDelegate respondsToSelector:@selector(didLongPress:)])
        {
            [self.mSpoilerDelegate didLongPress:_Gesture];
        }
    }
}



#pragma mark -
#pragma mark UIText View Delegate Methods



- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange
{
    if (self.mParent)
    {
        return [self.mParent textView:textView shouldInteractWithTextAttachment:textAttachment inRange:characterRange];
    }
    else if ([self.mDelegate respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:)])
    {
        return [self.mDelegate textView:textView shouldInteractWithTextAttachment:textAttachment inRange:characterRange];
    }
    
    return NO;
}


- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    if (self.mParent)
    {
        return [self.mParent textView:textView shouldInteractWithURL:URL inRange:characterRange];
    }
    else if ([self.mDelegate respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:)])
    {
        return [self.mDelegate textView:textView shouldInteractWithURL:URL inRange:characterRange];
    }
    
    return NO;
}


@end
