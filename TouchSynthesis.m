//
//  TouchSynthesis.m
//  SelfTesting
//
//  Created by Matt Gallagher on 23/11/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//

#import "TouchSynthesis.h"

@implementation UITouch (Synthesize)

//
// initInView
//
// Creats a UITouch, centered on the specified view, in the view's window.
//
- (id)initInView:(UIView *)view
{
	return [self initInView:view hitTest:YES];
}


//
// initInView:hitTest
//
// Creats a UITouch, centered on the specified view, in the view's window.
// Determines the target view by either performing a hit test, or just
// forcing the tap to land on the passed-in view.
//
- (id)initInView:(UIView *)view hitTest:(BOOL)hitTest {
	if (self = [super init]) {
		CGRect frameInWindow;
		if ([view isKindOfClass:[UIWindow class]])
		{
			frameInWindow = view.frame;
		}
		else
		{
			frameInWindow =
			[view.window convertRect:view.frame fromView:view.superview];
		}
		CGPoint location = CGPointMake(frameInWindow.origin.x + 0.5 * frameInWindow.size.width,
									   frameInWindow.origin.y + 0.5 * frameInWindow.size.height);
		
		_tapCount = 1;
		_locationInWindow = location;
		_previousLocationInWindow = location;
		
		UIView *target = hitTest ?
		[view.window hitTest:_locationInWindow withEvent:nil] :
		view;
		
		_view = [target retain];
		_window = [view.window retain];
		_phase = UITouchPhaseBegan;
		_touchFlags._firstTouchForView = 1;
		_touchFlags._isTap = 1;
		_timestamp = [NSDate timeIntervalSinceReferenceDate];
	}
	return self;
}

//
// setPhase:
//
// Setter to allow access to the _phase member.
//
- (void)setPhase:(UITouchPhase)phase
{
	_phase = phase;
	_timestamp = [NSDate timeIntervalSinceReferenceDate];
}

//
// setLocationInWindow:
//
// Setter to allow access to the _locationInWindow member.
//
- (void)setLocationInWindow:(CGPoint)location
{
	_previousLocationInWindow = _locationInWindow;
	_locationInWindow = location;
	_timestamp = [NSDate timeIntervalSinceReferenceDate];
}

//
// moveLocationInWindow:
//
// Adjusts location slightly.
//
- (void)moveLocationInWindow
{
	CGPoint moveTo = CGPointMake(_locationInWindow.x + 20, _locationInWindow.y);
	[self setLocationInWindow:moveTo];
}

@end

//
// GSEvent is an undeclared object. We don't need to use it ourselves but some
// Apple APIs (UIScrollView in particular) require the x and y fields to be present.
//
@interface GSEventProxy : NSObject
{
@public
	int ignored1[5];
	float x;
	float y;
	int ignored2[24];
}
@end
@implementation GSEventProxy
@end

//
// PublicEvent
//
// A dummy class used to gain access to UIEvent's private member variables.
// If UIEvent changes at all, this will break.
//
@interface PublicEvent : NSObject
{
@public
    GSEventProxy           *_event;
    NSTimeInterval          _timestamp;
    NSMutableSet           *_touches;
    CFMutableDictionaryRef  _keyedTouches;
}
@end

@implementation PublicEvent
@end

//
// UIEvent (Synthesize)
//
// A category to allow creation of a touch event.
//
@implementation UIEvent (Synthesize)

- (id)initWithTouch:(UITouch *)touch {
	if (self == [super init]) {
		UIEventFake *selfFake = (UIEventFake*)self;
		selfFake->_touches = [[NSMutableSet setWithObject:touch] retain];
		selfFake->_timestamp = [NSDate timeIntervalSinceReferenceDate];
		
		CGPoint location = [touch locationInView:touch.window];
		GSEventFake* fakeGSEvent = [[GSEventFake alloc] init];
		fakeGSEvent->x = location.x;
		fakeGSEvent->y = location.y;
		selfFake->_event = fakeGSEvent;
		
		CFMutableDictionaryRef dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 2,
																&kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFDictionaryAddValue(dict, touch.view, selfFake->_touches);
		CFDictionaryAddValue(dict, touch.window, selfFake->_touches);
		selfFake->_keyedTouches = dict;
	}
	return self;
}

- (void)moveLocation
{
	PublicEvent *publicEvent = (PublicEvent *)self;
	publicEvent->_timestamp = [NSDate timeIntervalSinceReferenceDate];
	publicEvent->_event->x += 20;
}

@end

