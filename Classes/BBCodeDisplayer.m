//
//  BBCodeDisplayer.m
//
//
//  Created by Raphaël Pinto on 04/09/2014.
//
// The MIT License (MIT)
// Copyright (c) 2015 Raphael Pinto.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.



#import "BBCodeDisplayer.h"
#import "Utils.h"
#import "CustomUITextView.h"



#define kOpeningQuote @"[citer]"
#define kClosingQuote @"[/citer]"
#define kOpeningSpoiler @"[spoiler]"
#define kClosingSpoiler @"[/spoiler]"
#define kSpoilerClosedHeight 25


@implementation BBCodeDisplayer



@synthesize delegate;
@synthesize spoilerDelegate;
@synthesize textColor;



#pragma mark -
#pragma mark Object Life Cycle Methods



- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        [self setupGestureRecognizer];
        
        self.linkColor = [UIColor colorWithRed:20.0/255.0f green:149.0/255.0f blue:180.0/255.0f alpha:1.0f];
    }
    
    return self;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        [self setupGestureRecognizer];
        
        self.linkColor = [UIColor colorWithRed:20.0/255.0f green:149.0/255.0f blue:180.0/255.0f alpha:1.0f];
    }
    
    return self;
}


- (void)dealloc
{
    [_longPress removeTarget:self action:@selector(didLongPress:)];
    [_tapGesture removeTarget:self action:@selector(onSpoilerButtonPressed)];
}



#pragma mark -
#pragma mark View Update Methods



- (void)setupWithBBCodeString:(NSString*)BBCode
                        width:(float)width
                currentHeight:(float)startingCurrentHeight
                     delegate:(NSObject<UITextViewDelegate>*)delegateObj
              spoilerDelegate:(NSObject<SpoilerDelegate>*)spoilerDelegateObj
{
    for (UIView* aView in self.subviews)
    {
        [aView removeFromSuperview];
    }
    self.delegate = delegateObj;
    self.spoilerDelegate = spoilerDelegateObj;
    self.BBCodeString = BBCode;
    self.currentHeight = startingCurrentHeight;
    self.currentCharacterIndex = 0;
    
    while (self.currentCharacterIndex < [BBCode length])
    {
        BOOL lNextTagIsQuote = YES;
        NSRange lNextOpenedTagRange = NSMakeRange(NSNotFound, 0);
        
        
        NSRange lOpeningQuoteRange = [self quoteRangeInString:self.BBCodeString  currentCharIndex:self.currentCharacterIndex];
        
        if (lOpeningQuoteRange.location != NSNotFound)
        {
            lNextOpenedTagRange = lOpeningQuoteRange;
        }
       
        NSRange lOpeningSpoilerRange = [self spoilerRangeInString:self.BBCodeString currentCharIndex:self.currentCharacterIndex];
        if ((lOpeningSpoilerRange.location != NSNotFound) && (lOpeningQuoteRange.location == NSNotFound || lOpeningSpoilerRange.location < lOpeningQuoteRange.location))
        {
            lNextTagIsQuote = NO;
            lNextOpenedTagRange = lOpeningSpoilerRange;
        }
    
        NSString* lText = nil;
        if ([self.BBCodeString length] >= self.currentCharacterIndex)
        {
            if (lNextOpenedTagRange.location != NSNotFound)
            {
                lText = [self.BBCodeString substringWithRange:NSMakeRange(self.currentCharacterIndex, lNextOpenedTagRange.location - self.currentCharacterIndex)];
            }
            else if ([self.BBCodeString length] >= self.currentCharacterIndex)
            {
                lText = [self.BBCodeString substringFromIndex:self.currentCharacterIndex];
            }
        }
        
        if (lNextOpenedTagRange.location != NSNotFound)
        {
            NSRange lSubRange = NSMakeRange(self.currentCharacterIndex, lNextOpenedTagRange.location - self.currentCharacterIndex);
            
            if ([lText length] > lSubRange.location + lSubRange.length)
            {
                lText =  [self.BBCodeString substringWithRange:lSubRange];
            }
        }
        if ([lText length] > 0)
        {
            [self addTextViewWithString:lText width:width];
        }
        
        if (lNextTagIsQuote && lOpeningQuoteRange.location != NSNotFound)
        {
            NSString* lText = [self.BBCodeString substringFromIndex:self.currentCharacterIndex];
            
            [self addQuoteWithString:lText width:width];
        }
        else if (lOpeningSpoilerRange.location != NSNotFound)
        {
            NSString* lText = [self.BBCodeString substringFromIndex:self.currentCharacterIndex];
            
            [self addSpoilerWithString:lText width:width];
        }
    }
    
    self.frame = CGRectMake(self.frame.origin.x,
                            self.frame.origin.y,
                            self.frame.size.width,
                            self.currentHeight + startingCurrentHeight);
}


- (void)setupWithBBCodeString:(NSString*)BBCode
                      width:(float)width
                   delegate:(NSObject<UITextViewDelegate>*)delegateObj
            spoilerDelegate:(NSObject<SpoilerDelegate>*)spoilerDelegateObj
{
    [self setupWithBBCodeString:BBCode
                          width:width
                  currentHeight:5
                       delegate:delegateObj
                spoilerDelegate:spoilerDelegateObj];
}


- (void)addTextViewWithString:(NSString*)BBCodeString
                        width:(float)width
{
    NSMutableAttributedString* lAttributedString = [BBCodeDisplayer attributtedStringFromBBCode:BBCodeString replaceSmiley:YES];

    if ([lAttributedString length] == 0)
    {
        self.currentCharacterIndex += [BBCodeString length];
        return;
    }
    
    CustomUITextView* lTextView = [[CustomUITextView alloc] initWithFrame:CGRectMake(5,
                                                                         _currentHeight,
                                                                         width - 5,
                                                                         5)];
    
    //lTextView.font = [UIFont fontWithName:@"Helvetica" size:12];
    [lTextView setAttributedText:lAttributedString];
    
    if (self.textColor)
    {
        lTextView.textColor = self.textColor;
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
    
    [lTextView setLinkTextAttributes:[NSDictionary dictionaryWithObject:self.linkColor forKey:NSForegroundColorAttributeName]];
    
    
    lTextView.delegate = self;
    [lTextView addGestureRecognizer:self.longPress];
    
    CGSize size = [lTextView sizeThatFits:CGSizeMake(lTextView.frame.size.width, FLT_MAX)];
    lTextView.frame = CGRectMake(5,
                                 _currentHeight,
                                 lTextView.frame.size.width,
                                 size.height);
    
    
    
    [self addSubview:lTextView];

    
    self.currentHeight += size.height;
    self.currentCharacterIndex += [BBCodeString length];
}


- (void)addQuoteWithString:(NSString*)BBCodeString width:(float)width
{
    NSString* lQuotedBBCode = [self getQuoteSubstringFromBBCodeString:BBCodeString];
    
    
    if ([lQuotedBBCode length] == 0)
    {
        self.currentCharacterIndex += [kOpeningQuote length];
        return;
    }
    
    BBCodeDisplayer* lQuote = [[BBCodeDisplayer alloc] initWithFrame:CGRectMake(5,
                                                                                _currentHeight + 5,
                                                                                width - 10,
                                                                                10)];
    lQuote.parent = self;
    lQuote.isQuote = YES;
    [lQuote setupWithBBCodeString:lQuotedBBCode
                          width:width - 10
                  currentHeight:5
                       delegate:self.delegate
                spoilerDelegate:self.spoilerDelegate];
    
    lQuote.delegate = self.delegate;
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
    
    self.currentHeight = lQuote.frame.origin.y + lQuote.frame.size.height;
    
    self.currentCharacterIndex += [lQuotedBBCode length] + [kOpeningQuote length] + [kClosingQuote length];
    self.hasAlreadyLoaded = YES;
}


- (void)addSpoilerWithString:(NSString*)BBCodeString width:(float)width
{
    NSString* lSpoiledBBCode = [self getSpoilerSubstringFromBBCodeString:BBCodeString];
    
    if ([lSpoiledBBCode length] == 0)
    {
        self.currentCharacterIndex += [kOpeningSpoiler length];
        return;
    }
    
    
    BBCodeDisplayer* lSpoiler = [[BBCodeDisplayer alloc] initWithFrame:CGRectMake(5,
                                                                                  _currentHeight + 5,
                                                                                  width - 10,
                                                                                  10)];
    
    lSpoiler.delegate = self.delegate;
    lSpoiler.clipsToBounds = YES;
    lSpoiler.parent = self;
    lSpoiler.isSpoiler = YES;
    
    [lSpoiler setupWithBBCodeString:lSpoiledBBCode
                              width:width - 10
                      currentHeight:kSpoilerClosedHeight
                           delegate:self.delegate
                    spoilerDelegate:self.spoilerDelegate];
    
    UILabel* lTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(5,
                                                                     0,
                                                                     width - 10,
                                                                     kSpoilerClosedHeight)];
    lTitleLabel.textColor = textColor;
    lTitleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
    lTitleLabel.attributedText = [BBCodeDisplayer attributtedStringFromBBCode:@"[b]Spoiler[/b]" replaceSmiley:NO];
    [lSpoiler addSubview:lTitleLabel];
    
    
    lSpoiler.currentHeight += 5;
    
    
    lSpoiler.backgroundColor = [UIColor colorWithRed:238.0f/255.0f green:238.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
    
    
    [self addSubview:lSpoiler];
    
    [lSpoiler addGestureRecognizer:lSpoiler.tapGesture];
    
    lSpoiler.isSpoilerClosed = YES;
    
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
                                kSpoilerClosedHeight);
    self.currentHeight = lSpoiler.frame.origin.y + lSpoiler.frame.size.height + 5;
    
    self.currentCharacterIndex += [lSpoiledBBCode length] + [kOpeningSpoiler length] + [kClosingSpoiler length];
}



#pragma mark -
#pragma mark BBCode Dicsplayer Delegate Methods



- (NSRange)quoteRangeInString:(NSString*)string currentCharIndex:(NSInteger)currentCharIndex
{
    if ([string length] < currentCharIndex)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    
    return [string rangeOfString:kOpeningQuote options:NSCaseInsensitiveSearch range:NSMakeRange(currentCharIndex, [string length] - currentCharIndex)];
}


- (NSRange)spoilerRangeInString:(NSString*)string currentCharIndex:(NSInteger)currentCharIndex
{
    if ([string length] < currentCharIndex)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    
    return [string rangeOfString:kOpeningSpoiler options:NSCaseInsensitiveSearch range:NSMakeRange(currentCharIndex, [string length] - currentCharIndex)];
}


- (NSRange)endingQuoteRangeInString:(NSString*)string currentCharIndex:(NSInteger)currentCharIndex
{
    if ([string length] < currentCharIndex)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    
    return [string rangeOfString:kClosingQuote options:NSCaseInsensitiveSearch range:NSMakeRange(currentCharIndex, [string length] - currentCharIndex)];
}


- (NSRange)endingSpoilerRangeInString:(NSString*)string currentCharIndex:(NSInteger)currentCharIndex
{
    if ([string length] < currentCharIndex)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    
    return [string rangeOfString:kClosingSpoiler options:NSCaseInsensitiveSearch range:NSMakeRange(currentCharIndex, [string length] - currentCharIndex)];
}



#pragma mark -
#pragma mark Text Compute Methods



+ (void)replaceBBCodeOpeningTag:(NSString*)openingTag
                     closingTag:(NSString*)closingTag
               attributedString:(NSMutableAttributedString*)attributedString
                      attribute:(NSString*)attributeName
                          value:(id)attributeValue
{
    NSString* lRegExOpenningTag = [openingTag stringByReplacingOccurrencesOfString:@"[" withString:@"\\["];
    lRegExOpenningTag = [lRegExOpenningTag stringByReplacingOccurrencesOfString:@"]" withString:@"\\]"];
    NSUInteger lRemovedCharacters = 0;
    
    NSString* lRegExClosingTag = [closingTag stringByReplacingOccurrencesOfString:@"[" withString:@"\\["];
    lRegExClosingTag = [lRegExClosingTag stringByReplacingOccurrencesOfString:@"]" withString:@"\\]"];
    lRegExClosingTag = [lRegExClosingTag stringByReplacingOccurrencesOfString:@"/" withString:@"\\/"];
    
    
    NSRegularExpression* lRegex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"%@((.|\\s)*?)%@", lRegExOpenningTag, lRegExClosingTag]options:0 error:NULL];
    NSArray* lMatches = [lRegex matchesInString:attributedString.string options:0 range:NSMakeRange(0, [attributedString.string length])];
    
    for (NSTextCheckingResult* aTextCheckingResult in lMatches)
    {
        NSString* lSubString = [attributedString.string substringWithRange:NSMakeRange([aTextCheckingResult range].location - lRemovedCharacters, [aTextCheckingResult range].length)];
        lSubString = [lSubString substringWithRange:NSMakeRange([openingTag length], [lSubString length] - [openingTag length] - [closingTag length])];
        
        [attributedString replaceCharactersInRange:NSMakeRange([aTextCheckingResult range].location - lRemovedCharacters, [aTextCheckingResult range].length) withString:lSubString];
        [attributedString addAttribute:attributeName value:attributeValue range:NSMakeRange([aTextCheckingResult range].location - lRemovedCharacters, [lSubString length])];
        
        lRemovedCharacters += [openingTag length] + [closingTag length];
    }
}


+ (void)replaceBBCodeLinkWithAttributedString:(NSMutableAttributedString*)attributedString
{
    NSRegularExpression* lRegex = [NSRegularExpression regularExpressionWithPattern:@"\\[url=(.*?)\\](.*?)\\[\\/url\\]" options:0 error:NULL];
    NSArray* lMatches = [lRegex matchesInString:attributedString.string options:0 range:NSMakeRange(0, [attributedString.string length])];
    NSUInteger lRemovedCharacters = 0;
    
    for (NSTextCheckingResult* aTextCheckingResult in lMatches)
    {
        NSString* lSubString = [attributedString.string substringWithRange:NSMakeRange([aTextCheckingResult range].location - lRemovedCharacters, [aTextCheckingResult range].length)];

        // Extract the full url
        NSRegularExpression* lRegexURL = [NSRegularExpression regularExpressionWithPattern:@"\\[url=(.*?)\\]" options:0 error:NULL];
        NSTextCheckingResult* lMatch2 = [lRegexURL firstMatchInString:lSubString options:0 range:NSMakeRange(0, [lSubString length])];
        NSRange lURLRange = NSMakeRange([lMatch2 range].location + 5, [lMatch2 range].length - ([lMatch2 range].location + 6)); // 6 is the [url=] lenght; 5 is the [url= lenght
        NSString* lURL = [lSubString substringWithRange:lURLRange];
        
        // Extract the visible URL
        NSRange lVisibleURLRange = NSMakeRange([aTextCheckingResult range].location + [lMatch2 range].length - lRemovedCharacters, [aTextCheckingResult range].length - ([lMatch2 range].length + 6)); // 6 is the lenght of [/url]
        NSString* lVisibleURL = [attributedString.string substringWithRange:lVisibleURLRange];
        
        
        // Replace the BBCode Link by the attributted string
        [attributedString replaceCharactersInRange:NSMakeRange([aTextCheckingResult range].location - lRemovedCharacters, [aTextCheckingResult range].length) withString:lVisibleURL];
        [attributedString addAttribute:NSLinkAttributeName value:lURL range:NSMakeRange([aTextCheckingResult range].location - lRemovedCharacters, [lVisibleURL length])];
        
        lRemovedCharacters += [lMatch2 range].length + 6;
    }
}


+ (void)replaceImageOpeningTag:(NSString*)openingTag
                    closingTag:(NSString*)closingTag
              attributedString:(NSMutableAttributedString*)attributedString
{
    NSRegularExpression* lRegex = [NSRegularExpression regularExpressionWithPattern:@"\\[img\\]([A-Za-z0-9_\\.\\-~:\\/]+?)\\[\\/img\\]" options:0 error:NULL];
    NSArray* lMatches = [lRegex matchesInString:attributedString.string options:0 range:NSMakeRange(0, [attributedString.string length])];
    NSUInteger lRemovedCharacters = 0;
    
    for (NSTextCheckingResult* aTextCheckingResult in lMatches)
    {
        NSString* lSubString = [attributedString.string substringWithRange:NSMakeRange([aTextCheckingResult range].location + [openingTag length] - lRemovedCharacters, [aTextCheckingResult range].length - [openingTag length] - [closingTag length])];
        
        [attributedString replaceCharactersInRange:NSMakeRange([aTextCheckingResult range].location - lRemovedCharacters, [aTextCheckingResult range].length) withString:lSubString];
        [attributedString addAttribute:NSLinkAttributeName value:[NSString stringWithFormat:@"IMAGE_COMMENT_FULLSCREEN_%@", lSubString] range:NSMakeRange([aTextCheckingResult range].location - lRemovedCharacters, [lSubString length])];
        
        //lRemovedCharacters = [aTextCheckingResult range].length - [lSubString length];
        lRemovedCharacters += [openingTag length] + [closingTag length];
        
    }
}


+ (NSMutableAttributedString*)attributtedStringFromBBCode:(NSString*)BBCodeString replaceSmiley:(BOOL)replaceSmiley
{
    NSString* lTrimmedString = [BBCodeString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSMutableAttributedString* AttributedString = [[NSMutableAttributedString alloc] initWithString:lTrimmedString];
   
    
   [self replaceBBCodeOpeningTag:@"[s]"
                       closingTag:@"[/s]"
                 attributedString:AttributedString
                        attribute:NSStrikethroughStyleAttributeName
                            value:[NSNumber numberWithInt:1]];
        
    [self replaceBBCodeOpeningTag:@"[i]"
                       closingTag:@"[/i]"
                 attributedString:AttributedString
                        attribute:NSFontAttributeName
                            value:[UIFont fontWithName:@"HelveticaNeue-Italic" size:13]];
    
    [self replaceBBCodeOpeningTag:@"[b]"
                       closingTag:@"[/b]"
                 attributedString:AttributedString
                        attribute:NSFontAttributeName
                            value:[UIFont fontWithName:@"Helvetica-Bold" size:12]];
    
    [self replaceBBCodeOpeningTag:@"[u]"
                       closingTag:@"[/u]"
                 attributedString:AttributedString
                        attribute:NSUnderlineStyleAttributeName
                            value:[NSNumber numberWithInt:1]];
    
    [BBCodeDisplayer replaceBBCodeLinkWithAttributedString:AttributedString];
    
    [BBCodeDisplayer replaceImageOpeningTag:@"[img]"
                                 closingTag:@"[/img]"
                           attributedString:AttributedString];
    
    
    if (replaceSmiley)
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


+ (void)replaceSmileyWithString:(NSString*)smileyString
                    smileyImage:(NSString*)smileyImage
                inMutableString:(NSMutableAttributedString*)mutableString
{
    [self replaceOneKindOfSmiley:[NSString stringWithFormat:@" %@", smileyString]
                           range:NSMakeRange(1,[smileyString length])
                     smileyImage:smileyImage
                 inMutableString:mutableString];
    [self replaceOneKindOfSmiley:[NSString stringWithFormat:@"%@ ", smileyString]
                           range:NSMakeRange(0,[smileyString length])
                     smileyImage:smileyImage
                 inMutableString:mutableString];
}


+ (void)replaceOneKindOfSmiley:(NSString*)smileyString
                         range:(NSRange)range
                   smileyImage:(NSString*)smileyImage
               inMutableString:(NSMutableAttributedString*)mutableString
{
    if ([mutableString.string length] == 0)
    {
        return;
    }
    
    
    NSRange lSmileyRange = [mutableString.string rangeOfString:smileyString];
    
    while (lSmileyRange.location != NSNotFound)
    {
        lSmileyRange = NSMakeRange(lSmileyRange.location + range.location, range.length);
        
        NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
        textAttachment.image = [UIImage imageNamed:smileyImage];
        /* textAttachment.bounds = CGRectMake(textAttachment.bounds.origin.x,
         textAttachment.bounds.origin.y,
         13, 13);*/
        NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:textAttachment];
        
        [mutableString replaceCharactersInRange:lSmileyRange withAttributedString:attrStringWithImage];
        
        lSmileyRange = [mutableString.string rangeOfString:smileyString];
    }
}



#pragma mark -
#pragma mark Data Management Methods



- (void)setupGestureRecognizer
{
    UILongPressGestureRecognizer* lGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPress:)];
    self.longPress = lGesture;
    [self addGestureRecognizer:self.longPress];
    
    UITapGestureRecognizer* lTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSpoilerButtonPressed)];
    self.tapGesture = lTapGesture;
}


- (NSString*)getSpoilerSubstringFromBBCodeString:(NSString*)BBCodeString
{
    
    NSRange lFirstOpenTagRange = [self spoilerRangeInString:_BBCodeString currentCharIndex:0];
    
    if (lFirstOpenTagRange.location == NSNotFound)
    {
        return nil;
    }
    
    unsigned long lCurrentCharLocation = lFirstOpenTagRange.location + lFirstOpenTagRange.length;
    int lNewOpenedTag = 0;
    
    do
    {
        NSRange lCloseTagRange = [self endingSpoilerRangeInString:_BBCodeString currentCharIndex:lCurrentCharLocation];
        
        if (lCloseTagRange.location == NSNotFound)
        {
            return nil;
        }
        
        
        NSRange lOpenTagRange = [self spoilerRangeInString:_BBCodeString currentCharIndex:lCurrentCharLocation];
        
        
        if (lOpenTagRange.location != NSNotFound && lOpenTagRange.location < lCloseTagRange.location)
        {
            lNewOpenedTag++;
            lCurrentCharLocation = lOpenTagRange.location + lOpenTagRange.length;
            
            continue;
        }
        else
        {
            if (lNewOpenedTag == 0)
            {
                return [_BBCodeString substringWithRange:NSMakeRange(lFirstOpenTagRange.location + [kOpeningSpoiler length], lCloseTagRange.location - lFirstOpenTagRange.location - [kOpeningSpoiler length])];
            }
            else
            {
                lNewOpenedTag--;
                
                lCurrentCharLocation = lCloseTagRange.location + lCloseTagRange.length;
                
                continue;
            }
        }
    }
    while (lNewOpenedTag >= 0);
    
    return nil;
    
    /*
    int lNewOpenedTag = 0;
    unsigned long lCurrentCharLocation = 0;
    
    
    while (lCurrentCharLocation < [BBCodeString length])
    {
        NSRange lOpenTagRange = [self spoilerRangeInString:BBCodeString currentCharIndex:lCurrentCharLocation];
        NSRange lCloseTagRange = [self endingSpoilerRangeInString:BBCodeString currentCharIndex:lCurrentCharLocation];
        
        
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
                return [[_BBCodeString substringFromIndex:_currentCharacterIndex + [kOpeningSpoiler length]] substringToIndex:lCloseTagRange.location - [kOpeningSpoiler length]];
            }
            // Another open tag has been opened
            else
            {
                lNewOpenedTag--;
                
                lCurrentCharLocation = lCloseTagRange.location + lCloseTagRange.length;
            }
        }
    }
    
    return nil;*/
}


- (NSString*)getQuoteSubstringFromBBCodeString:(NSString*)BBCodeString
{
    NSRange lFirstOpenTagRange = [self quoteRangeInString:_BBCodeString currentCharIndex:0];
    
    if (lFirstOpenTagRange.location == NSNotFound)
    {
        return nil;
    }
    
    unsigned long lCurrentCharLocation = lFirstOpenTagRange.location + lFirstOpenTagRange.length;
    int lNewOpenedTag = 0;
    
    do
    {
        NSRange lCloseTagRange = [self endingQuoteRangeInString:_BBCodeString currentCharIndex:lCurrentCharLocation];
        
        if (lCloseTagRange.location == NSNotFound)
        {
            return nil;
        }
        
        
        NSRange lOpenTagRange = [self quoteRangeInString:_BBCodeString currentCharIndex:lCurrentCharLocation];
        
        
        if (lOpenTagRange.location != NSNotFound && lOpenTagRange.location < lCloseTagRange.location)
        {
            lNewOpenedTag++;
            lCurrentCharLocation = lOpenTagRange.location + lOpenTagRange.length;
            
            continue;
        }
        else
        {
            if (lNewOpenedTag == 0)
            {
                return [_BBCodeString substringWithRange:NSMakeRange(lFirstOpenTagRange.location + [kOpeningQuote length], lCloseTagRange.location - lFirstOpenTagRange.location - [kOpeningQuote length])];
            }
            else
            {
                lNewOpenedTag--;
                
                lCurrentCharLocation = lCloseTagRange.location + lCloseTagRange.length;
                
                continue;
            }
        }
    }
    while (lNewOpenedTag >= 0);
    
    return nil;
}


+ (NSArray*)getSubstringForOpeningTag:(NSString*)_Tag
                          toEndingTag:(NSString*)_EndingTag
                       fromBBCodeString:(NSString*)_BBCodeString
                  currentCharLocation:(unsigned long)_CurrentCharLocation
{
    int lNewOpenedTag = 0;
    NSRange lOpenTagRange = NSMakeRange(NSNotFound, 0);
    
    
    while (_CurrentCharLocation < [_BBCodeString length])
    {
        NSRange lOpenTagRangeTmp = [_BBCodeString rangeOfString:_Tag
                                                      options:NSCaseInsensitiveSearch
                                                        range:NSMakeRange(_CurrentCharLocation, [_BBCodeString length] - _CurrentCharLocation)];
        
        NSRange lCloseTagRange = [_BBCodeString rangeOfString:_EndingTag
                                                    options:NSCaseInsensitiveSearch
                                                      range:NSMakeRange(_CurrentCharLocation, [_BBCodeString length] - _CurrentCharLocation)];
        
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
                NSString* lSubString = [[_BBCodeString substringFromIndex:lOpenTagRange.location + lOpenTagRange.length] substringToIndex:lCloseTagRange.location - lOpenTagRange.location - lOpenTagRange.length];
                
                
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
                                       fromBBCodeString:(NSString*)_BBCodeString
                                  currentCharLocation:(unsigned long)_CurrentCharLocation
{
    int lNewOpenedTag = 0;
    NSRange lOpenTagRange = NSMakeRange(NSNotFound, 0);
    
    
    NSString* lLink = nil;
    NSRange lURLRange = NSMakeRange(NSNotFound, 0);
    
    
    while (_CurrentCharLocation < [_BBCodeString length])
    {
        NSRange lOpenTagRangeTmp = [_BBCodeString rangeOfString:_Tag
                                                      options:NSCaseInsensitiveSearch
                                                        range:NSMakeRange(_CurrentCharLocation, [_BBCodeString length] - _CurrentCharLocation)];
        
        
        NSRange lCloseTagRange = [_BBCodeString rangeOfString:_EndingTag
                                                    options:NSCaseInsensitiveSearch
                                                      range:NSMakeRange(_CurrentCharLocation, [_BBCodeString length] - _CurrentCharLocation)];
        
        
        // Open Tag reached
        if (lOpenTagRangeTmp.location != NSNotFound && lCloseTagRange.location != NSNotFound && lOpenTagRangeTmp.location < lCloseTagRange.location)
        {
            if (lOpenTagRange.location == NSNotFound)
            {
                lOpenTagRange = lOpenTagRangeTmp;
                
                lURLRange = [_BBCodeString rangeOfString:@"]"
                                               options:NSCaseInsensitiveSearch
                                                 range:NSMakeRange(lOpenTagRangeTmp.location + lOpenTagRangeTmp.length, [_BBCodeString length] - lOpenTagRangeTmp.location - lOpenTagRangeTmp.length)];
                
                if ([_BBCodeString length] > lOpenTagRangeTmp.location + lOpenTagRangeTmp.length + lURLRange.location - lOpenTagRangeTmp.location - lOpenTagRangeTmp.length)
                {
                    lLink = [_BBCodeString substringWithRange:NSMakeRange(lOpenTagRangeTmp.location + lOpenTagRangeTmp.length, lURLRange.location - lOpenTagRangeTmp.location - lOpenTagRangeTmp.length)];
                }
                
                
                NSRange lBuggedOpenTagRange = [lLink rangeOfString:_Tag
                                                           options:NSCaseInsensitiveSearch
                                                             range:NSMakeRange(0, [lLink length])];
         
                if (lBuggedOpenTagRange.location != NSNotFound)
                {
                    lOpenTagRange = NSMakeRange(lOpenTagRangeTmp.location + lOpenTagRangeTmp.length + lBuggedOpenTagRange.location, lBuggedOpenTagRange.length);
                    
                    lURLRange = [_BBCodeString rangeOfString:@"]"
                                                   options:NSCaseInsensitiveSearch
                                                     range:NSMakeRange(lOpenTagRange.location, [_BBCodeString length] - lOpenTagRange.location - lOpenTagRange.length)];
               
                    
                    if ([_BBCodeString length] > lOpenTagRange.location + lOpenTagRange.length + lURLRange.location - lOpenTagRange.location - lOpenTagRange.length)
                    {
                        lLink = [_BBCodeString substringWithRange:NSMakeRange(lOpenTagRange.location + lOpenTagRange.length, lURLRange.location - lOpenTagRange.location - lOpenTagRange.length)];
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
                
                if ([_BBCodeString length] > lDisplayedStringRange.location && lDisplayedStringRange.length != FLT_MAX)
                {
                    NSString* lSubStr = [_BBCodeString substringFromIndex:lDisplayedStringRange.location];
                    
                    if ([lSubStr length] > lDisplayedStringRange.length)
                    {
                        NSString* lSubString = [[_BBCodeString substringFromIndex:lDisplayedStringRange.location] substringToIndex:lDisplayedStringRange.length];
                        
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
    self.currentHeight += _AdjustVal;
    
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
    
    
    if (self.parent)
    {
        [self.parent updateSize:_AdjustVal forSubView:self];
    }
    else
    {
        if (spoilerDelegate && [spoilerDelegate respondsToSelector:@selector(BBCodeDisplayerSpoilerPressed:)])
        {
            [spoilerDelegate BBCodeDisplayerSpoilerPressed:self];
        }
    }
}


+ (float)calculateBBCodeHeightForBBCodeText:(NSString*)_BBCodeText maxWidth:(float)_MaxWidth
{
    BBCodeDisplayer* lBBCodeDisplay = [[BBCodeDisplayer alloc] init];
    [lBBCodeDisplay setupWithBBCodeString:_BBCodeText
                                  width:_MaxWidth
                               delegate:nil
                        spoilerDelegate:nil];
    return lBBCodeDisplay.currentHeight;
}



#pragma mark -
#pragma mark User Interaction Methods



- (IBAction)onSpoilerButtonPressed
{
    self.isSpoilerClosed = !self.isSpoilerClosed;
    
    if (!self.isSpoilerClosed)
    {
        self.frame = CGRectMake(self.frame.origin.x,
                                self.frame.origin.y,
                                self.frame.size.width,
                                self.currentHeight);
        
        [self.parent updateSize:self.currentHeight - kSpoilerClosedHeight forSubView:self];
    }
    else
    {
        self.frame = CGRectMake(self.frame.origin.x,
                                self.frame.origin.y,
                                self.frame.size.width,
                                kSpoilerClosedHeight);
        
        [self.parent updateSize:- (self.currentHeight - kSpoilerClosedHeight) forSubView:self];
    }
}


- (IBAction)didLongPress:(UIGestureRecognizer*)_Gesture
{
    if(_Gesture.state == UIGestureRecognizerStateBegan)
    {
        if (self.parent)
        {
            [self.parent didLongPress:_Gesture];
        }
        
        else if ([self.spoilerDelegate respondsToSelector:@selector(BBCodeDisplayer:didLongPress:)])
        {
            [self.spoilerDelegate BBCodeDisplayer:self didLongPress:_Gesture];
        }
    }
}



#pragma mark -
#pragma mark UIText View Delegate Methods



- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange
{
    if (self.parent)
    {
        return [self.parent textView:textView shouldInteractWithTextAttachment:textAttachment inRange:characterRange];
    }
    else if ([self.delegate respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:)])
    {
        return [self.delegate textView:textView shouldInteractWithTextAttachment:textAttachment inRange:characterRange];
    }
    
    return NO;
}


- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    if (self.parent)
    {
        return [self.parent textView:textView shouldInteractWithURL:URL inRange:characterRange];
    }
    else if ([self.delegate respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:)])
    {
        return [self.delegate textView:textView shouldInteractWithURL:URL inRange:characterRange];
    }
    
    return NO;
}


@end
