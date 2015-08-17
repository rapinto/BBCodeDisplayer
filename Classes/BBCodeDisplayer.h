//
//  BBCodeDisplayer.h
//  Dealabs
//
//  Created by Raphaël Pinto on 04/09/2014.
//  Copyright (c) 2014 HUME Network. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SpoilerDelegate.h"




@interface BBCodeDisplayer : UIView <UITextViewDelegate>



@property (nonatomic, retain) NSString* mHTMLString;
@property (nonatomic) float mCurrentHeight;
@property (nonatomic) NSUInteger mCurrentCharacterIndex;
@property (nonatomic, assign) NSObject<UITextViewDelegate>* mDelegate;
@property (nonatomic) BOOL mIsSpoilerClosed;
@property (nonatomic) BOOL mHasAlreadyLoaded;
@property (nonatomic, retain) BBCodeDisplayer* mParent;
@property (nonatomic, assign) NSObject<SpoilerDelegate>* mSpoilerDelegate;
@property (nonatomic, retain) UILongPressGestureRecognizer* mLongPress;
@property (nonatomic, retain) UITapGestureRecognizer* mTapGesture;
@property (nonatomic) BOOL mIsQuote;
@property (nonatomic) BOOL mIsSpoiler;
@property (nonatomic, retain) UIColor* mTextColor;
@property (nonatomic, retain) UIColor* mLinkColor;



- (void)setupWithHTMLString:(NSString*)_HTML
                      width:(float)_Width
                   delegate:(NSObject<UITextViewDelegate>*)_Delegate
            spoilerDelegate:(NSObject<SpoilerDelegate>*)_SpoilerDelegate;



+ (NSMutableAttributedString*)attributtedStringFromBBCode:(NSString*)_BBCodeString replaceSmiley:(BOOL)_ReplaceSmiley;
+ (void)replaceSmileyWithString:(NSString*)_SmileyString
                    smileyImage:(NSString*)_SmileyImage
                inMutableString:(NSMutableAttributedString*)_MutableString;
+ (float)calculateBBCodeHeightForBBCodeText:(NSString*)_BBCodeText maxWidth:(float)_MaxWidth;



@end
