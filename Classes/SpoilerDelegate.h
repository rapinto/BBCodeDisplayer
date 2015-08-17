//
//  SpoilerDelegate.h
//  Dealabs
//
//  Created by Raphaël Pinto on 08/09/2014.
//  Copyright (c) 2014 HUME Network. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SpoilerDelegate <NSObject>



- (void)BBCodeSpoilerPressed:(id)_Sender;
- (void)didLongPress:(UIGestureRecognizer*)_Gesture;

                            
                              
@end
