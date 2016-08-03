//
//  MainViewController.m
//  CalendarDemo - Graphical Calendars Library for iOS
//
//  Copyright (c) 2014-2015 Awesome Inc. All rights reserved.
//

#import "MainViewController.h"
#import "WeekViewController.h"
#import "MonthViewController.h"
#import "YearViewController.h"
#import "NSCalendar+MGCAdditions.h"
#import "WeekSettingsViewController.h"
#import "MonthSettingsViewController.h"

//2592000
#define TIMEINTERVALFTOUPDATE 86400
#define CALENDARID "av1rspu9cnsotu0tcdncocqseg@group.calendar.google.com"
//*****************************  API  *****************************

static NSString *const kKeychainItemName = @"Google Calendar";
static NSString *const kClientID = @"739355203143-ij8qqrgjs4i26v7sv4ofgsb5kts72d51.apps.googleusercontent.com";
//*****************************  API  end**************************


typedef enum : NSUInteger
{
    CalendarViewWeekType  = 0,
    CalendarViewMonthType = 1,
    CalendarViewYearType = 2
} CalendarViewType;


@interface MainViewController ()<YearViewControllerDelegate, WeekViewControllerDelegate>

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic) EKCalendarChooser *calendarChooser;
@property (nonatomic) BOOL firstTimeAppears;
@property (nonatomic) WeekViewController *weekViewController;
@property (nonatomic) MonthViewController *monthViewController;
@property (nonatomic) YearViewController *yearViewController;

//*****************************  API  *****************************
@property (retain) GTLCalendarCalendarList *calendarList;
@property (retain) GTLServiceTicket *calendarListTicket;
@property (retain) NSError *calendarListFetchError;
@property (nonatomic, strong) NSDate *synTime;
@property (nonatomic, strong) NSArray *previousCheckedEventInGoogle;
//*****************************  API  end**************************

@property (weak, nonatomic) IBOutlet UIBarButtonItem *showCalendars;
@property (weak, nonatomic) IBOutlet UIButton *refresh;


@end


@implementation MainViewController

- (IBAction)refresh:(UIButton *)sender {
    if ([self.calendarViewController.visibleCalendars count] == 1 && [[[self.calendarViewController.visibleCalendars allObjects][0] title] isEqualToString:@"Conference Room Calendar"] ){
        [self fetchEvents];
    } else {
        NSLog(@"In func refresh: do not refresh because no Calendar!");
    }
}

//*****************************  API  *****************************
@synthesize service = _service;
//*****************************  API  end**************************

#pragma mark - UIViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        _eventStore = [[EKEventStore alloc]init];
    }

//    ********************************* source print *********************************
    for (EKSource *source in self.eventStore.sources){
        NSLog(@"source is %@", source.title);
        if (source.sourceType == EKSourceTypeLocal)
        {
            NSLog(@"Local source is %@", source.title);
        }

    }

    
    
//************************************** EKCalendarList Delete Calendar**************************************
//    NSArray <EKCalendar *> *ekCalendarList = [self.eventStore calendarsForEntityType:EKEntityTypeEvent];
//    for (EKCalendar *ekCalendar in ekCalendarList)
//    {
//        NSLog(@"%@,--%@", ekCalendar.title,ekCalendar.calendarIdentifier);
//        if ([ekCalendar.title isEqualToString:@"Conference Room Calendar"])
//        {
//            NSLog(@"About to remove %@!",ekCalendar.title);
//            NSError *err = nil;
//            BOOL result = [self.eventStore removeCalendar:ekCalendar commit:YES error:&err];
//            if (result) {
//                NSLog(@"Deleted calendar from event store.");
//            } else {
//                NSLog(@"Deleting calendar failed: %@.", err);
//            }
//        }
//        
//    }
//************************************** end
    return self;
}

- (void)callLater
{
    NSLog(@"In call later");
    
    
    
    
    //    ********************************* source print *********************************
//        for (EKSource *source in self.eventStore.sources){
//            NSLog(@"source is %@", source.title);
//            
//            if (source.sourceType == EKSourceTypeLocal)
//            {
//                NSLog(@"Local source is %@", source.title);
//            }
//    
//        }
    
    //************************************** EKCalendarList Delete Calendar**************************************
    NSArray <EKCalendar *> *ekCalendarList = [self.eventStore calendarsForEntityType:EKEntityTypeEvent];
    BOOL hasCalendar = NO;
    for (EKCalendar *ekCalendar in ekCalendarList)
    {
        NSLog(@"%@,--%@", ekCalendar.title,ekCalendar.calendarIdentifier);
        if ([ekCalendar.title isEqualToString:@"Conference Room Calendar"])
        {
            //            NSLog(@"About to remove %@!",ekCalendar.title);
            //            NSError *err = nil;
            //            BOOL result = [self.eventStore removeCalendar:ekCalendar commit:YES error:&err];
            //            if (result) {
            //                NSLog(@"Deleted calendar from event store.");
            //            } else {
            //                NSLog(@"Deleting calendar failed: %@.", err);
            //            }
            self.calendarViewController.visibleCalendars = [NSSet setWithObject:ekCalendar];
            hasCalendar = YES;
            NSLog(@"In func callLater: this is a conference room calendar!!");
            break;
        }
    }
    if (!hasCalendar){
        NSLog(@"In func callLater: this is not a conference room calendar!!");
        EKCalendar *onlyCalendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:self.eventStore];
        [onlyCalendar setTitle:@"Conference Room Calendar"];
        // find local source
        EKSource *localSource = nil;
        for (EKSource *source in self.eventStore.sources)
            if (source.sourceType == EKSourceTypeLocal)
            {
                localSource = source;
                break;
            }
        
        [onlyCalendar setSource:localSource];
        NSError *error;
        if (![_eventStore saveCalendar:onlyCalendar commit:YES error:&error]){
            NSLog(@"Add Calendar fail!!! %@",error);
        }
        NSArray <EKCalendar *> *setCalendarList = [self.eventStore calendarsForEntityType:EKEntityTypeEvent];
        for (EKCalendar *c in setCalendarList){
            if ([c.title isEqualToString:@"Conference Room Calendar"]){
                self.calendarViewController.visibleCalendars = [NSSet setWithObject:c];
                break;
            }
        }
    }
    //************************************** end
    
    
    //************************************** set only one visibale calendar *************************************
    if (self.calendarViewController.visibleCalendars != nil){
        if ([self.calendarViewController.visibleCalendars count] > 1){
            for (EKCalendar *visibleCalendar in self.calendarViewController.visibleCalendars){
                //NSLog(@"visibleCalendar: %@",visibleCalendar.title);
                if ([visibleCalendar.title isEqualToString:@"Conference Room Calendar"]){
                    NSLog(@"find Calendar in visibaleCalendars");
                    self.calendarViewController.visibleCalendars = [NSSet setWithObject:visibleCalendar];
                }
            }
        }
    }

    
    //************************************** end **************************************
    
    //************************************** testing (delete event) **************************************
    NSDate *dstart =  [[NSDate alloc] initWithTimeIntervalSinceNow:1];
    NSDate *dend = [[NSDate alloc] initWithTimeIntervalSinceNow:TIMEINTERVALFTOUPDATE];
    NSLog(@"d description: %@ - %@",[dstart description],[dend description]);
    for (EKCalendar *ca in self.calendarViewController.visibleCalendars){
        if ([ca.title isEqualToString:@"Conference Room Calendar"]){
            NSLog(@"In line 1");
            NSArray<EKEvent *> * es =[_eventStore eventsMatchingPredicate:[_eventStore predicateForEventsWithStartDate:dstart endDate:dend calendars:[NSArray arrayWithObject:ca]]];
            if (es == nil) {
                NSLog(@"In initWithCoder: [EKEvent] is nil");
            }else{
                for (EKEvent *e in es){
                    NSLog(@"About to detele event:%@", e.title);
                    NSError *err;
                    if ( [_eventStore removeEvent:e span:EKSpanThisEvent error:&err]){
                        NSLog(@"successfully delete");
                    }else { NSLog(@"not delete error is %@",err);}
                }
            }
        }
    }
    //************************************** end
    
    [self fetchEvents];
    self.refresh.enabled = YES;
    self.refresh.alpha = 1;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //hide viewChooser and Calendar setting
    self.viewChooser.enabled = NO;
    self.viewChooser.alpha = 0;
    //self.showCalendars.enabled = NO;
    self.refresh.enabled = NO;
    self.refresh.alpha = 0.5;

    
    _previousCheckedEventInGoogle = nil;
    
    
    [self performSelector:@selector(callLater) withObject:self afterDelay:2];
    
    [self refreshEvery_Seconds:30];
    
//*****************************  API  *****************************
// Create a UITextView to display output.


// Initialize the Google Calendar API service & load existing credentials from the keychain if available.
self.service = [[GTLServiceCalendar alloc] init];
self.service.authorizer =
[GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                      clientID:kClientID
                                                  clientSecret:nil];

//*****************************  API  end**************************
    
    NSString *calID = [[NSUserDefaults standardUserDefaults]stringForKey:@"calendarIdentifier"];
    self.calendar = [NSCalendar mgc_calendarFromPreferenceString:calID];
    
    NSUInteger firstWeekday = [[NSUserDefaults standardUserDefaults]integerForKey:@"firstDay"];
    if (firstWeekday != 0) {
        self.calendar.firstWeekday = firstWeekday;
    } else {
        [[NSUserDefaults standardUserDefaults]registerDefaults:@{ @"firstDay" : @(self.calendar.firstWeekday) }];
    }
    
    self.dateFormatter = [NSDateFormatter new];
    self.dateFormatter.calendar = self.calendar;
    
    if (isiPad) {
        //NSLog(@"---------------- iPAD ------------------");
    }
    else{
        //NSLog(@"---------------- iPhone ------------------");
        self.navigationItem.leftBarButtonItem.customView = self.currentDateLabel;
    }
	
	CalendarViewController *controller = [self controllerForViewType:CalendarViewWeekType];
	[self addChildViewController:controller];
	[self.containerView addSubview:controller.view];
	controller.view.frame = self.containerView.bounds;
	[controller didMoveToParentViewController:self];
	
	self.calendarViewController = controller;
    self.firstTimeAppears = YES;
}

- (void) refreshEvery_Seconds:(int) time
{
    
    //NSTimer calling Method B, as long the audio file is playing, every x seconds.
    [NSTimer scheduledTimerWithTimeInterval:time
                                     target:self
                                   selector:@selector(AARefresh:)
                                   userInfo:nil
                                    repeats:YES];
}

- (void) AARefresh:(NSTimer *)timer
{
    //NSLog(@"Call methodB every %f seconds",timer.timeInterval);
    //[self fetchEvents];
}

- (void)viewDidAppear:(BOOL)animated
{

    
//*****************************  API  *****************************
if (!self.service.authorizer.canAuthorize) {
    // Not yet authorized, request authorization by pushing the login UI onto the UI stack.
    [self presentViewController:[self createAuthController] animated:YES completion:nil];
    
} else {
    NSLog(@"The current time before fetchEvents is: %@", _synTime);
    //[self fetchEvents];
}


    
//*****************************  API  end**************************
    
    [super viewDidAppear:animated];
    
    if (self.firstTimeAppears) {
        NSDate *date = [self.calendar mgc_startOfWeekForDate:[NSDate date]];
        [self.calendarViewController moveToDate:date animated:NO];
        self.firstTimeAppears = NO;
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    UINavigationController *nc = (UINavigationController*)[segue destinationViewController];
    
    if ([segue.identifier isEqualToString:@"dayPlannerSettingsSegue"]) {
        WeekSettingsViewController *settingsViewController = (WeekSettingsViewController*)nc.topViewController;
        WeekViewController *weekController = (WeekViewController*)self.calendarViewController;
        settingsViewController.dayPlannerView = weekController.dayPlannerView;
    }
    else if ([segue.identifier isEqualToString:@"monthPlannerSettingsSegue"]) {
        MonthSettingsViewController *settingsViewController = (MonthSettingsViewController*)nc.topViewController;
        MonthViewController *monthController = (MonthViewController*)self.calendarViewController;
        settingsViewController.monthPlannerView = monthController.monthPlannerView;
    }
    
    BOOL doneButton = (self.traitCollection.verticalSizeClass != UIUserInterfaceSizeClassRegular || self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassRegular);
    if (doneButton) {
         nc.topViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissSettings:)];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    UINavigationController *nc = (UINavigationController*)self.presentedViewController;
    if (nc) {
        BOOL hide = (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular && self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular);
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissSettings:)];
        nc.topViewController.navigationItem.rightBarButtonItem = hide ? nil : doneButton;
    }
}

#pragma mark - Private

- (WeekViewController*)weekViewController
{
    if (_weekViewController == nil) {
        _weekViewController = [[WeekViewController alloc]initWithEventStore:self.eventStore];
        _weekViewController.calendar = self.calendar;
        _weekViewController.delegate = self;
    }
    return _weekViewController;
}

- (MonthViewController*)monthViewController
{
    if (_monthViewController == nil) {
        _monthViewController = [[MonthViewController alloc]initWithEventStore:self.eventStore];
        _monthViewController.calendar = self.calendar;
        _monthViewController.delegate = self;
    }
    return _monthViewController;
}

- (YearViewController*)yearViewController
{
    if (_yearViewController == nil) {
        _yearViewController = [[YearViewController alloc]init];
        _yearViewController.calendar = self.calendar;
        _yearViewController.delegate = self;
    }
    return _yearViewController;
}

- (CalendarViewController*)controllerForViewType:(CalendarViewType)type
{
    switch (type)
    {
        case CalendarViewWeekType:  return self.weekViewController;
        case CalendarViewMonthType: return self.monthViewController;
        case CalendarViewYearType:  return self.yearViewController;
    }
    return nil;
}

-(void)moveToNewController:(CalendarViewController*)newController atDate:(NSDate*)date
{
    [self.calendarViewController willMoveToParentViewController:nil];
    [self addChildViewController:newController];
    
    [self transitionFromViewController:self.calendarViewController toViewController:newController duration:.5 options:UIViewAnimationOptionTransitionFlipFromLeft animations:^
     {
         newController.view.frame = self.containerView.bounds;
         newController.view.hidden = YES;
     } completion:^(BOOL finished)
     {
         [self.calendarViewController removeFromParentViewController];
         [newController didMoveToParentViewController:self];
         self.calendarViewController = newController;
         [newController moveToDate:date animated:NO];
         newController.view.hidden = NO;
     }];
}

#pragma mark - Actions

-(IBAction)switchControllers:(UISegmentedControl*)sender
{
//    self.settingsButtonItem.enabled = NO;
//    
//    NSDate *date = [self.calendarViewController centerDate];
//    CalendarViewController *controller = [self controllerForViewType:sender.selectedSegmentIndex];
//    [self moveToNewController:controller atDate:date];
//    
//    
//    if ([controller isKindOfClass:WeekViewController.class] || [controller isKindOfClass:MonthViewController.class]) {
//        self.settingsButtonItem.enabled = YES;
//    }
}

- (IBAction)showToday:(id)sender
{
    [self.calendarViewController moveToDate:[NSDate date] animated:YES];
}

- (IBAction)nextPage:(id)sender
{
    [self.calendarViewController moveToNextPageAnimated:YES];
}

- (IBAction)previousPage:(id)sender
{
    [self.calendarViewController moveToPreviousPageAnimated:YES];
}

- (IBAction)showCalendars:(id)sender
{
    //[self showGoogleCalendarList];
    
    for (EKCalendar *ekca in self.calendarViewController.visibleCalendars){
        NSLog(@"%@", ekca.title);
        NSLog(@"%@", ekca.CGColor);
    }
    
    if ([self.calendarViewController respondsToSelector:@selector(visibleCalendars)]) {
        self.calendarChooser = [[EKCalendarChooser alloc]initWithSelectionStyle:EKCalendarChooserSelectionStyleMultiple displayStyle:EKCalendarChooserDisplayAllCalendars eventStore:self.eventStore];
        self.calendarChooser.delegate = self;
        self.calendarChooser.showsDoneButton = YES;
        self.calendarChooser.selectedCalendars = self.calendarViewController.visibleCalendars;
    }
    
    if (self.calendarChooser) {
        UINavigationController *nc = [[UINavigationController alloc]initWithRootViewController:self.calendarChooser];
        self.calendarChooser.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(calendarChooserStartEdit)];
        nc.modalPresentationStyle = UIModalPresentationPopover;
 
        [self showDetailViewController:nc sender:self];
        
        UIPopoverPresentationController *popController = nc.popoverPresentationController;
        popController.barButtonItem = (UIBarButtonItem*)sender;
    }

}

- (IBAction)showSettings:(id)sender
{
    if ([self.calendarViewController isKindOfClass:WeekViewController.class]) {
        [self performSegueWithIdentifier:@"dayPlannerSettingsSegue" sender:nil];
    }
    else if ([self.calendarViewController isKindOfClass:MonthViewController.class]) {
        [self performSegueWithIdentifier:@"monthPlannerSettingsSegue" sender:nil];
    }
}

- (void)dismissSettings:(UIBarButtonItem*)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)calendarChooserStartEdit
{
    self.calendarChooser.editing = YES;
    self.calendarChooser.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(calendarChooserEndEdit)];
}

- (void)calendarChooserEndEdit
{
    self.calendarChooser.editing = NO;
    self.calendarChooser.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(calendarChooserStartEdit)];
}

#pragma mark - YearViewControllerDelegate

- (void)yearViewController:(YearViewController*)controller didSelectMonthAtDate:(NSDate*)date
{
    CalendarViewController *controllerNew = [self controllerForViewType:CalendarViewMonthType];
    [self moveToNewController:controllerNew atDate:date];
    self.viewChooser.selectedSegmentIndex = CalendarViewMonthType;
}

#pragma mark - CalendarViewControllerDelegate

- (void)calendarViewController:(CalendarViewController*)controller didShowDate:(NSDate*)date
{
    if (controller.class == YearViewController.class)
        [self.dateFormatter setDateFormat:@"yyyy"];
    else
        [self.dateFormatter setDateFormat:@"MMMM yyyy"];
    
    NSString *str = [self.dateFormatter stringFromDate:date];
    self.currentDateLabel.text = str;
    [self.currentDateLabel sizeToFit];
}

- (void)calendarViewController:(CalendarViewController*)controller didSelectEvent:(EKEvent*)event
{
    //NSLog(@"calendarViewController:didSelectEvent");
}

#pragma mark - MGCDayPlannerEKViewControllerDelegate

- (UINavigationController*)navigationControllerForEKEventViewController
{
//    if (!isiPad) {
//        return self.navigationController;
//    }
    return nil;
}


#pragma mark - EKCalendarChooserDelegate

- (void)calendarChooserSelectionDidChange:(EKCalendarChooser*)calendarChooser
{
    if ([self.calendarViewController respondsToSelector:@selector(setVisibleCalendars:)]) {
        self.calendarViewController.visibleCalendars = calendarChooser.selectedCalendars;
    }
}

- (void)calendarChooserDidFinish:(EKCalendarChooser*)calendarChooser
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

//*****************************  API  *****************************
// Construct a query and get a list of upcoming events from the user calendar. Display the
// start dates and event summaries in the UITextView.
- (void)fetchEvents {
    GTLQueryCalendar *query = [GTLQueryCalendar queryForEventsListWithCalendarId:@CALENDARID];
    query.timeMax = [GTLDateTime dateTimeWithDate:[NSDate dateWithTimeIntervalSinceNow:TIMEINTERVALFTOUPDATE]
                                         timeZone:[NSTimeZone localTimeZone]];;
    query.timeMin = [GTLDateTime dateTimeWithDate:[NSDate date]
                                         timeZone:[NSTimeZone localTimeZone]];;
    query.singleEvents = YES;
    query.orderBy = kGTLCalendarOrderByStartTime;
    
    [self.service executeQuery:query
                      delegate:self
             didFinishSelector:@selector(displayResultWithTicket:finishedWithObject:error:)];
    
}

- (void)displayResultWithTicket:(GTLServiceTicket *)ticket
             finishedWithObject:(GTLCalendarEvents *)events
                          error:(NSError *)error {
    [self addEventsToApp:events];
    
    if (self.previousCheckedEventInGoogle != nil){
        [self addEventsToGoogle:events];
    }
    
    [self putEventsToPreviousCheckedGoogleEvent];
    
    //************************************** Log out some outputs **************************************
    if (error == nil) {
        NSMutableString *eventString = [[NSMutableString alloc] init];
        if (events.items.count > 0) {
            [eventString appendFormat:@"Upcoming events within timeInterval: %d\n",TIMEINTERVALFTOUPDATE];
            for (GTLCalendarEvent *event in events) {
                GTLDateTime *start = event.start.dateTime ?: event.start.date;
                GTLDateTime *end = event.end.dateTime ?: event.start.date;
    NSString *startString =
    [NSDateFormatter localizedStringFromDate:[start date]
                                   dateStyle:NSDateFormatterShortStyle
                                   timeStyle:NSDateFormatterShortStyle];
    NSString *endString = [NSDateFormatter localizedStringFromDate:[end date]
                                   dateStyle:NSDateFormatterMediumStyle
                                                         timeStyle:NSDateFormatterMediumStyle];
            [eventString appendFormat:@"%@ - %@ - %@\n", startString, endString, event.summary];
        }
    } else {
        [eventString appendString:@"No upcoming events found."];
    }
    NSLog(@"In displayWith: %@",eventString);
    for (EKEvent *ekEvent in _previousCheckedEventInGoogle){
            NSLog(@"In displayWith: In previousEvents: %@", ekEvent.title);
        }
        
    } else {
        [self showAlert:@"Error" message:error.localizedDescription];
    }
    //************************************** logout end **************************************
}

- (void) putEventsToPreviousCheckedGoogleEvent
{
    GTLQueryCalendar *query = [GTLQueryCalendar queryForEventsListWithCalendarId:@CALENDARID];
    query.timeMax = [GTLDateTime dateTimeWithDate:[NSDate dateWithTimeIntervalSinceNow:TIMEINTERVALFTOUPDATE]
                                         timeZone:[NSTimeZone localTimeZone]];;
    query.timeMin = [GTLDateTime dateTimeWithDate:[NSDate date]
                                         timeZone:[NSTimeZone localTimeZone]];;
    query.singleEvents = YES;
    query.orderBy = kGTLCalendarOrderByStartTime;
    
    [self.service executeQuery:query
             completionHandler:^(GTLServiceTicket *ticket, id events, NSError *error){
                 NSMutableArray *previousEvents = [[NSMutableArray alloc]init];
                 for (GTLCalendarEvent *event in events){
                     //************************************** testing (add event) **************************************
                     GTLDateTime *start = event.start.dateTime ?: event.start.date;
                     GTLDateTime *end = event.end.dateTime ?: event.start.date;
                     NSDate *addEventStartDay = start.date;
                     NSDate *addEventEndDay = end.date;
                     EKEvent *addEvent = [EKEvent eventWithEventStore:_eventStore];
                     addEvent.title = event.summary;
                     addEvent.startDate = addEventStartDay;
                     addEvent.endDate = addEventEndDay;
                     [previousEvents addObject:addEvent];
                 }
                 _previousCheckedEventInGoogle = previousEvents;
             }];
}

//
- (void) addEventsToApp: (GTLCalendarEvents *)events
{
    if ([self.calendarViewController.visibleCalendars count] == 1){

        for (GTLCalendarEvent *event in events){
            //************************************** testing (add event) **************************************
            GTLDateTime *start = event.start.dateTime ?: event.start.date;
            GTLDateTime *end = event.end.dateTime ?: event.start.date;
            NSDate *addEventStartDay = start.date;
            NSDate *addEventEndDay = end.date;
            EKEvent *addEvent = [EKEvent eventWithEventStore:_eventStore];
            
            addEvent.title = event.summary;
            addEvent.startDate = addEventStartDay;
            addEvent.endDate = addEventEndDay;
            addEvent.notes = event.descriptionProperty;
            [addEvent setCalendar:[self.calendarViewController.visibleCalendars allObjects][0]];
            NSLog(@"In func addEventsToApp: checkSameEvent addEvent: %@ - %@ - %@",addEvent.title,addEvent.startDate,addEvent.endDate);
            NSArray<EKEvent *> * es =[_eventStore eventsMatchingPredicate:[_eventStore predicateForEventsWithStartDate:addEventStartDay endDate:addEventEndDay calendars:[self.calendarViewController.visibleCalendars allObjects]]];
            
            BOOL sameEvent = NO;
            if (es == nil) {
                NSLog(@"In func addEventsToApp: [EKEvent] is nil");
                sameEvent = NO;
            }else{
                for (EKEvent *e in es){
                    NSLog(@"In func addEventsToApp: checkSameEvent e: %@ - %@ - %@",e.title,e.startDate,e.endDate);
                    NSLog(@"In func addEventsToApp: checkSameEvent addEvent: %@ - %@ - %@",addEvent.title,addEvent.startDate,addEvent.endDate);
                    if ([e.title isEqualToString:addEvent.title] && [e.startDate isEqual:addEvent.startDate] && [e.endDate isEqual:addEvent.endDate]){
                        sameEvent = YES;
                        NSLog(@"In func addEventsToApp: Find same event in APP %@", e.title);
                        break;
                    }
                }
            }
            
            BOOL inPreviousEvents = NO;
            if (_previousCheckedEventInGoogle == nil){
                inPreviousEvents = NO;
            } else {
                for (EKEvent *e in _previousCheckedEventInGoogle){
                    if ([e.title isEqualToString:addEvent.title] && [e.startDate isEqual:start.date] && [e.endDate isEqual:end.date]){
                        inPreviousEvents = YES;
                    }
                }
            }
            
            
            if (!sameEvent && !inPreviousEvents){
                NSError *err;
                if ([_eventStore saveEvent:addEvent span:EKSpanThisEvent error:&err]){
                    NSLog(@"In func addEventsToApp: %@ Save successfully",addEvent.title);
                } else {
                    NSLog(@"In func addEventsToApp: Not saved");
                }
            }else if (!sameEvent && inPreviousEvents){
                [self deleteFromGoogle: event];
            }else {NSLog(@"In func addEventsToApp: find same event, do not add");}
        }
    }
    //************************************** testing (add event) end**************************************
}

- (void)deleteFromApp: (EKEvent *)event
{
    //************************************** testing (delete event) *************************************
    
    NSLog(@"In func deleteFromApp: About to detele event:%@", event.title);
    NSError *err;
    if ( [_eventStore removeEvent:event span:EKSpanThisEvent error:&err]){
        NSLog(@"%@ successfully delete",event.title);
    }else { NSLog(@"not delete error is %@",err);}

    //************************************** end
    
}

//
- (void)deleteFromGoogle: (GTLCalendarEvent *)event
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete Alert" message:[NSString stringWithFormat:@"Do you want to delete event %@ on Google Calendar?",event.summary] preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Detele" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        GTLQueryCalendar *query = [GTLQueryCalendar queryForEventsDeleteWithCalendarId:@CALENDARID
                                                                               eventId:event.identifier];
        [self.service executeQuery:query
                 completionHandler:^(GTLServiceTicket *ticket, id nilObject, NSError *error){
                     if (error == nil) {
                         NSLog(@"In func deleteFromGoogle: delete event %@ successfully!!", event.summary);
                     } else {
                         NSLog(@"In func deleteFromGoogle: not deleted");
                     }}];
    }]];
    
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self closeAlertview];
    }]];
    
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

-(void)closeAlertview
{
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


//
- (void)addEventsToGoogle:(GTLCalendarEvents *)events
{
    //************************************** testing (update event to google) **************************************
    NSDate *dstart =  [[NSDate alloc] initWithTimeIntervalSinceNow:1];
    NSDate *dend = [[NSDate alloc] initWithTimeIntervalSinceNow:TIMEINTERVALFTOUPDATE];
    NSLog(@"d description: %@ - %@",[dstart description],[dend description]);
    if ([self.calendarViewController.visibleCalendars count] == 1){
        NSArray<EKEvent *> * addEvents =[_eventStore eventsMatchingPredicate:[_eventStore predicateForEventsWithStartDate:dstart endDate:dend calendars:[self.calendarViewController.visibleCalendars allObjects]]];
        for (EKEvent *addEvent in addEvents){
            BOOL sameEventInGoogle = NO;
            NSLog(@"Starts at %@ and Ends at %@, the event is %@",addEvent.startDate,addEvent.endDate, addEvent.title);
            for (GTLCalendarEvent *event in events)
            {
                GTLDateTime *start = event.start.dateTime ?: event.start.date;
                GTLDateTime *end = event.end.dateTime ?: event.start.date;
                NSLog(@"Find same event with summary %@,time is %@ - %@",event.summary,start.date,end.date);
                if ([event.summary isEqualToString:addEvent.title] && [start.date isEqualToDate:addEvent.startDate] && [end.date isEqualToDate:addEvent.endDate])
                {
                    sameEventInGoogle = YES;
                    NSLog(@"Find the same event!!!do not update!");
                    break;
                }
            }
        
            BOOL inPreviousEvents = NO;
            if (_previousCheckedEventInGoogle == nil){
                inPreviousEvents = NO;
            } else {
                for (EKEvent *e in _previousCheckedEventInGoogle){
                    if ([e.title isEqualToString:addEvent.title] && [e.startDate isEqual:addEvent.startDate] && [e.endDate isEqual:addEvent.endDate]){
                        inPreviousEvents = YES;
                    }
                }
            }
            
            if (!sameEventInGoogle && !inPreviousEvents){
                
                GTLCalendarEvent *newEvent = [GTLCalendarEvent object];
                newEvent.summary = addEvent.title;
                GTLDateTime *startDateTime = [GTLDateTime dateTimeWithDate:addEvent.startDate
                                                                  timeZone:[NSTimeZone systemTimeZone]];
                GTLDateTime *endDateTime = [GTLDateTime dateTimeWithDate:addEvent.endDate
                                                                timeZone:[NSTimeZone systemTimeZone]];
                newEvent.start = [GTLCalendarEventDateTime object];
                newEvent.start.dateTime = startDateTime;
                
                newEvent.end = [GTLCalendarEventDateTime object];
                newEvent.end.dateTime = endDateTime;
                
                GTLCalendarEventReminder *reminder = [GTLCalendarEventReminder object];
                reminder.minutes = [NSNumber numberWithInteger:10];
                reminder.method = @"email";
                
                newEvent.descriptionProperty = addEvent.notes;
                
                newEvent.reminders = [GTLCalendarEventReminders object];
                newEvent.reminders.overrides = [NSArray arrayWithObject:reminder];
                newEvent.reminders.useDefault = [NSNumber numberWithBool:NO];

                GTLQueryCalendar *query = [GTLQueryCalendar queryForEventsInsertWithObject:newEvent
                                                                                calendarId:@CALENDARID];
                NSLog(@"About to add event to Google Calendar!");
                [self.service executeQuery:query
                         completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
                             if (error == nil) {
                                 GTLCalendarEvent *event = object;
                                 NSLog(@"%@ add successfully!",event.summary);
                             } else {
                                 NSLog(@"***********error in add event: %@",error);
                             }
                             [self putEventsToPreviousCheckedGoogleEvent];
                         }];
                }else if (!sameEventInGoogle && inPreviousEvents){
                    [self deleteFromApp:addEvent];
            }
        }
    }
    //************************* end here *************************
}

//
- (void)showGoogleCalendarList
{
    //************************************** testing (calendar list) **************************************
        self.calendarList = nil;
        self.calendarListFetchError = nil;
        GTLServiceCalendar *Cservice = self.service;
        GTLQueryCalendar *query = [GTLQueryCalendar queryForCalendarListList];
    
        query.minAccessRole = kGTLCalendarMinAccessRoleOwner;
    
        self.calendarListTicket = [Cservice executeQuery:query
                                      completionHandler:^(GTLServiceTicket *ticket,
                                                          id calendarList, NSError *error) {
                                          // Callback
    
                                          self.calendarList = calendarList;
                                          self.calendarListFetchError = error;
                                          self.calendarListTicket = nil;
                                          for (NSString *cal in calendarList){
                                              NSLog(@"*********There is calendar in Google %@*********", cal);
                                          }
    
                                      }];
    //************************* end here *************************
}

// Creates the auth controller for authorizing access to Google Calendar API.
- (GTMOAuth2ViewControllerTouch *)createAuthController {
    GTMOAuth2ViewControllerTouch *authController;
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    NSArray *scopes = [NSArray arrayWithObjects:kGTLAuthScopeCalendar, nil];
    authController = [[GTMOAuth2ViewControllerTouch alloc]
                      initWithScope:[scopes componentsJoinedByString:@" "]
                      clientID:kClientID
                      clientSecret:nil
                      keychainItemName:kKeychainItemName
                      delegate:self
                      finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    return authController;
}

// Handle completion of the authorization process, and update the Google Calendar API
// with the new credentials.
- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)authResult
                 error:(NSError *)error {
    if (error != nil) {
        [self showAlert:@"Authentication Error" message:error.localizedDescription];
        self.service.authorizer = nil;
    }
    else {
        self.service.authorizer = authResult;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

// Helper for showing an alert
- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok =
    [UIAlertAction actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action)
     {
         [alert dismissViewControllerAnimated:YES completion:nil];
     }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
    
}
//*****************************  API  end*****************************
@end
