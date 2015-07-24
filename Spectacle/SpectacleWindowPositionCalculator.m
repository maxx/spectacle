#import "SpectacleWindowPositionCalculator.h"

#import "SpectacleConstants.h"
#import "SpectacleHistoryItem.h"
#import "SpectacleUtilities.h"

#define AgainstTheLeftEdgeOfScreen(a, b) (a.origin.x <= b.origin.x)
#define AgainstTheRightEdgeOfScreen(a, b) (CGRectGetMaxX(a) >= CGRectGetMaxX(b))
#define AgainstTheTopEdgeOfScreen(a, b) (CGRectGetMaxY(a) >= CGRectGetMaxY(b))
#define AgainstTheBottomEdgeOfScreen(a, b) (a.origin.y <= b.origin.y)

#pragma mark -

@implementation SpectacleWindowPositionCalculator

+ (SpectacleCalculationResult *)calculateWindowRect: (CGRect)windowRect visibleFrameOfScreen: (CGRect)visibleFrameOfScreen action: (SpectacleWindowAction)action {
    CGRect calculatedWindowRect = windowRect;

    if ((action >= SpectacleWindowActionRightHalf) && (action <= SpectacleWindowActionLowerRight)) {
        calculatedWindowRect.origin.x = visibleFrameOfScreen.origin.x + floor(visibleFrameOfScreen.size.width / 2.0f);
    } else if (MovingToCenterRegionOfDisplay(action)) {
        calculatedWindowRect.origin.x = floor(visibleFrameOfScreen.size.width / 2.0f) - floor(calculatedWindowRect.size.width / 2.0f) + visibleFrameOfScreen.origin.x;
    } else if (!MovingToThirdOfDisplay(action)) {
        calculatedWindowRect.origin.x = visibleFrameOfScreen.origin.x;
    }

    if (MovingToTopRegionOfDisplay(action)) {
        calculatedWindowRect.origin.y = visibleFrameOfScreen.origin.y + floor(visibleFrameOfScreen.size.height / 2.0f) + remainder(visibleFrameOfScreen.size.height, 2.0f);
    } else if (MovingToCenterRegionOfDisplay(action)) {
        calculatedWindowRect.origin.y = floor(visibleFrameOfScreen.size.height / 2.0f) - floor(calculatedWindowRect.size.height / 2.0f) + visibleFrameOfScreen.origin.y;
    } else if (!MovingToThirdOfDisplay(action)) {
        calculatedWindowRect.origin.y = visibleFrameOfScreen.origin.y;
    }

    if ((action == SpectacleWindowActionLeftHalf) || (action == SpectacleWindowActionRightHalf)) {
        return [SpectacleWindowPositionCalculator calculateLeftOrRightHalfRect:windowRect visibleFrameOfScreen: visibleFrameOfScreen withAction: action];
    } else if ((action == SpectacleWindowActionTopHalf) || (action == SpectacleWindowActionBottomHalf)) {
        return [SpectacleWindowPositionCalculator calculateTopOrBottomHalfRect:windowRect visibleFrameOfScreen: visibleFrameOfScreen withAction: action];
    } else if (MovingToUpperOrLowerLeftOfDisplay(action) || MovingToUpperOrLowerRightDisplay(action)) {
        calculatedWindowRect.size.width = floor(visibleFrameOfScreen.size.width / 2.0f);
        calculatedWindowRect.size.height = floor(visibleFrameOfScreen.size.height / 2.0f);
    } else if (!MovingToCenterRegionOfDisplay(action) && !MovingToThirdOfDisplay(action)) {
        calculatedWindowRect.size.width = visibleFrameOfScreen.size.width;
        calculatedWindowRect.size.height = visibleFrameOfScreen.size.height;
    }

    if (MovingToThirdOfDisplay(action)) {
        calculatedWindowRect = [SpectacleWindowPositionCalculator findThirdForWindowRect: calculatedWindowRect visibleFrameOfScreen: visibleFrameOfScreen withAction: action];
    }
    
    calculatedWindowRect.origin.x += SpectacleUselessGap;
    calculatedWindowRect.origin.y += SpectacleUselessGap;
    calculatedWindowRect.size.width -= 2*SpectacleUselessGap;
    calculatedWindowRect.size.height -= 2*SpectacleUselessGap;


    return [SpectacleCalculationResult resultWithAction: action windowRect: calculatedWindowRect];
}

+ (SpectacleCalculationResult *)calculateResizedWindowRect: (CGRect)windowRect visibleFrameOfScreen: (CGRect)visibleFrameOfScreen sizeOffset: (CGFloat)sizeOffset action: (SpectacleWindowAction)action {
    CGRect calculatedWindowRect = windowRect;

    calculatedWindowRect.size.width = calculatedWindowRect.size.width + sizeOffset;
    calculatedWindowRect.origin.x = calculatedWindowRect.origin.x - floor(sizeOffset / 2.0f);

    if (AgainstTheRightEdgeOfScreen(windowRect, visibleFrameOfScreen)) {
        calculatedWindowRect.origin.x = CGRectGetMaxX(visibleFrameOfScreen) - calculatedWindowRect.size.width;

        if (AgainstTheLeftEdgeOfScreen(windowRect, visibleFrameOfScreen)) {
            calculatedWindowRect.size.width = visibleFrameOfScreen.size.width;
        }
    }

    if (AgainstTheLeftEdgeOfScreen(windowRect, visibleFrameOfScreen)) {
        calculatedWindowRect.origin.x = visibleFrameOfScreen.origin.x;
    }

    if (calculatedWindowRect.size.width >= visibleFrameOfScreen.size.width) {
        calculatedWindowRect.size.width = visibleFrameOfScreen.size.width;
    }

    calculatedWindowRect.size.height = calculatedWindowRect.size.height + sizeOffset;
    calculatedWindowRect.origin.y = calculatedWindowRect.origin.y - floor(sizeOffset / 2.0f);

    if (AgainstTheTopEdgeOfScreen(windowRect, visibleFrameOfScreen)) {
        calculatedWindowRect.origin.y = CGRectGetMaxY(visibleFrameOfScreen) - calculatedWindowRect.size.height;

        if (AgainstTheBottomEdgeOfScreen(windowRect, visibleFrameOfScreen)) {
            calculatedWindowRect.size.height = visibleFrameOfScreen.size.height;
        }
    }

    if (AgainstTheBottomEdgeOfScreen(windowRect, visibleFrameOfScreen)) {
        calculatedWindowRect.origin.y = visibleFrameOfScreen.origin.y;
    }

    if (calculatedWindowRect.size.height >= visibleFrameOfScreen.size.height) {
        calculatedWindowRect.size.height = visibleFrameOfScreen.size.height;
        calculatedWindowRect.origin.y = windowRect.origin.y;
    }

    if (CGRectEqualToRect(windowRect, visibleFrameOfScreen) && (sizeOffset < 0)) {
        calculatedWindowRect.size.width = windowRect.size.width + sizeOffset;
        calculatedWindowRect.origin.x = windowRect.origin.x - floor(sizeOffset / 2.0f);

        calculatedWindowRect.size.height = windowRect.size.height + sizeOffset;
        calculatedWindowRect.origin.y = windowRect.origin.y - floor(sizeOffset / 2.0f);
    }

    if ([SpectacleWindowPositionCalculator isWindowRect: calculatedWindowRect tooSmallRelativeToVisibleFrameOfScreen: visibleFrameOfScreen]) {
        calculatedWindowRect = windowRect;
    }

    calculatedWindowRect.size.height -= 2*SpectacleUselessGap;
    calculatedWindowRect.size.width -= 2*SpectacleUselessGap;
    calculatedWindowRect.origin.x -= SpectacleUselessGap;
    calculatedWindowRect.origin.y -= SpectacleUselessGap;
    
    return [SpectacleCalculationResult resultWithAction: action windowRect: calculatedWindowRect];
}

#pragma mark -

+ (NSArray *)thirdsFromVisibleFrameOfScreen: (CGRect)visibleFrameOfScreen {
    NSMutableArray *result = [NSMutableArray new];
    NSInteger i = 0;

    for (i = 0; i < 3; i++) {
        CGRect thirdOfScreen = visibleFrameOfScreen;

        thirdOfScreen.origin.x = visibleFrameOfScreen.origin.x + (floor(visibleFrameOfScreen.size.width / 3.0f) * i);
        thirdOfScreen.size.width = floor(visibleFrameOfScreen.size.width / 3.0f);

        [result addObject: [SpectacleHistoryItem historyItemFromAccessibilityElement: nil windowRect: thirdOfScreen]];
    }

    for (i = 0; i < 3; i++) {
        CGRect thirdOfScreen = visibleFrameOfScreen;

        thirdOfScreen.origin.y = visibleFrameOfScreen.origin.y + visibleFrameOfScreen.size.height - (floor(visibleFrameOfScreen.size.height / 3.0f) * (i + 1));
        thirdOfScreen.size.height = floor(visibleFrameOfScreen.size.height / 3.0f);

        [result addObject: [SpectacleHistoryItem historyItemFromAccessibilityElement: nil windowRect: thirdOfScreen]];
    }

    return result;
}

+ (CGRect)findThirdForWindowRect: (CGRect)windowRect visibleFrameOfScreen: (CGRect)visibleFrameOfScreen withAction: (SpectacleWindowAction)action {
    NSArray *thirds = [SpectacleWindowPositionCalculator thirdsFromVisibleFrameOfScreen: visibleFrameOfScreen];
    CGRect result = [thirds[0] windowRect];
    NSInteger i = 0;

    for (i = 0; i < thirds.count; i++) {
        CGRect currentWindowRect = [thirds[i] windowRect];

        if (RectCenteredWithinRect(currentWindowRect, windowRect)) {
            NSInteger j = i;

            if (action == SpectacleWindowActionNextThird) {
                if (++j >= thirds.count) {
                    j = 0;
                }
            } else if (action == SpectacleWindowActionPreviousThird) {
                if (--j < 0) {
                    j = thirds.count - 1;
                }
            }

            result = [thirds[j] windowRect];

            break;
        }
    }
    
    result.origin.x += SpectacleUselessGap;
    result.origin.y += SpectacleUselessGap;
    result.size.width -= 2*SpectacleUselessGap;
    result.size.height -= 2*SpectacleUselessGap;

    return result;
}

#pragma mark -

+ (BOOL)isWindowRect: (CGRect)windowRect tooSmallRelativeToVisibleFrameOfScreen: (CGRect)visibleFrameOfScreen {
    CGFloat minimumWindowRectWidth = floor(visibleFrameOfScreen.size.width / SpectacleMinimumWindowSizeRatio);
    CGFloat minimumWindowRectHeight = floor(visibleFrameOfScreen.size.height / SpectacleMinimumWindowSizeRatio);

    return (windowRect.size.width <= minimumWindowRectWidth) || (windowRect.size.height <= minimumWindowRectHeight);
}

#pragma mark -

+ (SpectacleCalculationResult *)calculateLeftOrRightHalfRect: (CGRect)windowRect visibleFrameOfScreen: (CGRect)visibleFrameOfScreen withAction: (SpectacleWindowAction)action {
    CGRect oneHalfRect = visibleFrameOfScreen;

    oneHalfRect.size.width = floor(oneHalfRect.size.width / 2.0f);

    if (action == SpectacleWindowActionRightHalf) {
        oneHalfRect.origin.x += oneHalfRect.size.width;
    }

    if (fabs(CGRectGetMidY(windowRect) - CGRectGetMidY(oneHalfRect)) <= 1.0f) {
        CGRect oneThirdsRect = oneHalfRect;

        oneThirdsRect.size.width = floor(visibleFrameOfScreen.size.width / 3.0f);

        if (action == SpectacleWindowActionRightHalf) {
            oneThirdsRect.origin.x = visibleFrameOfScreen.origin.x + visibleFrameOfScreen.size.width - oneThirdsRect.size.width;
        }

        if (RectCenteredWithinRect(oneHalfRect, windowRect)) {
            return [SpectacleCalculationResult resultWithAction: SpectacleWindowActionNextThird windowRect: oneThirdsRect];
        }
        
        if (RectCenteredWithinRect(oneThirdsRect, windowRect)) {
            CGRect twoThirdRect = oneHalfRect;
            
            twoThirdRect.size.width = floor(visibleFrameOfScreen.size.width * 2 / 3.0f);
            
            if (action == SpectacleWindowActionRightHalf) {
                twoThirdRect.origin.x = visibleFrameOfScreen.origin.x + visibleFrameOfScreen.size.width - twoThirdRect.size.width;
            }
            
            return [SpectacleCalculationResult resultWithAction: SpectacleWindowActionNextThird windowRect: twoThirdRect];
        }
    }
    
    oneHalfRect.origin.x += SpectacleUselessGap;
    oneHalfRect.origin.y += SpectacleUselessGap;
    oneHalfRect.size.width -= 2*SpectacleUselessGap;
    oneHalfRect.size.height -= 2*SpectacleUselessGap;

    return [SpectacleCalculationResult resultWithAction: action windowRect: oneHalfRect];
}

#pragma mark -

+ (SpectacleCalculationResult *)calculateTopOrBottomHalfRect: (CGRect)windowRect visibleFrameOfScreen: (CGRect)visibleFrameOfScreen withAction: (SpectacleWindowAction)action {
    CGRect oneHalfRect = visibleFrameOfScreen;

    oneHalfRect.size.height = floor(oneHalfRect.size.height / 2.0f);

    if (action == SpectacleWindowActionTopHalf) {
        oneHalfRect.origin.y += oneHalfRect.size.height + remainder(visibleFrameOfScreen.size.height, 2.0f);
    }

    if (fabs(CGRectGetMidX(windowRect) - CGRectGetMidX(oneHalfRect)) <= 1.0f) {
        CGRect oneThirdRect = oneHalfRect;

        oneThirdRect.size.height = floor(visibleFrameOfScreen.size.height / 3.0f);

        if (action == SpectacleWindowActionTopHalf) {
            oneThirdRect.origin.y = visibleFrameOfScreen.origin.y + visibleFrameOfScreen.size.height - oneThirdRect.size.height;
        }

        if (RectCenteredWithinRect(oneHalfRect, windowRect)) {
            return [SpectacleCalculationResult resultWithAction: SpectacleWindowActionNextThird windowRect: oneThirdRect];
        }

        if (RectCenteredWithinRect(oneThirdRect, windowRect)) {
            CGRect twoThirdsRect = oneHalfRect;

            twoThirdsRect.size.height = floor(visibleFrameOfScreen.size.height * 2 / 3.0f);

            if (action == SpectacleWindowActionTopHalf) {
                twoThirdsRect.origin.y = visibleFrameOfScreen.origin.y + visibleFrameOfScreen.size.height - twoThirdsRect.size.height;
            }

            return [SpectacleCalculationResult resultWithAction: SpectacleWindowActionNextThird windowRect: twoThirdsRect];
        }
    }
    
    oneHalfRect.origin.x += SpectacleUselessGap;
    oneHalfRect.origin.y += SpectacleUselessGap;
    oneHalfRect.size.width -= 2*SpectacleUselessGap;
    oneHalfRect.size.height -= 2*SpectacleUselessGap;

    return [SpectacleCalculationResult resultWithAction: action windowRect: oneHalfRect];
}

@end
