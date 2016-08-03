//
//  WeekSettingsViewController.h
//  CalendarDemo - Graphical Calendars Library for iOS
//
//  Copyright (c) 2014-2015 Awesome Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGCDayPlannerView.h"

@protocol WeekSettingsViewControllerDelegate;


@interface WeekSettingsViewController : UITableViewController

@property (nonatomic) MGCDayPlannerView *dayPlannerView;

@end
