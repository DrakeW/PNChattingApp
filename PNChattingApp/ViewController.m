//
//  ViewController.m
//  PNChattingApp
//
//  Created by Junyu Wang on 4/14/15.
//  Copyright (c) 2015 junyuwang. All rights reserved.
//

#import "ViewController.h"
#import "PNImports.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //created the pubnub object
    PNConfiguration *myConfig = [PNConfiguration configurationForOrigin:@"pubsub.pubnub.com"
                                                             publishKey:@"demo"
                                                           subscribeKey:@"demo"
                                                              secretKey:@"demo"];
    [PubNub setConfiguration:myConfig];
    
    [PubNub connect];
    
    //define my channel
    PNChannel *myChannel = [PNChannel channelWithName:@"demo" shouldObservePresence:YES];

    //add client state observer
    [[PNObservationCenter defaultCenter] addClientConnectionStateObserver:self
                                                        withCallbackBlock:^(NSString *origin, BOOL connected, PNError *connectionError) {
                                                            if (connected) {
                                                                NSLog(@"OBSERVER: Successful Connection");
                                                                
                                                                [PubNub subscribeOnChannel:myChannel];
                                                            }else if (!connected || connectionError) {
                                                                NSLog(@"OBSERVER: Error %@, Connection Failed", connectionError.localizedDescription);
                                                            }
                                                        }];
    
    //add subscription observer
    [[PNObservationCenter defaultCenter] addClientChannelSubscriptionStateObserver:self
                                                                 withCallbackBlock:^(PNSubscriptionProcessState state, NSArray *channels, PNError *error) {
                                                                     switch (state) {
                                                                         case PNSubscriptionProcessSubscribedState:
                                                                             NSLog(@"OBSERVER: subscribed to channel %@",channels[0]);
                                                                             [PubNub sendMessage:[NSString stringWithFormat:@"Welcom to demo channel biach!"] toChannel:myChannel];
                                                                             break;
                                                                         case PNSubscriptionProcessNotSubscribedState:
                                                                             NSLog(@"OBSERVER: Not subscribed to Channel: %@, Error: %@", channels[0], error);
                                                                             break;
                                                                         case PNSubscriptionProcessWillRestoreState:
                                                                             NSLog(@"OBSERVER: Will re-subscribe to Channel: %@", channels[0]);
                                                                             break;
                                                                         case PNSubscriptionProcessRestoredState:
                                                                             NSLog(@"OBSERVER: Will re-subscribe to Channel: %@", channels[0]);
                                                                             break;
                                                                     }
                                                                 }];
    //add message received observer
    [[PNObservationCenter defaultCenter] addMessageReceiveObserver:self
                                                         withBlock:^(PNMessage *msg) {
                                                             NSLog(@"OBSERVER: Channel: %@, Message: %@", msg.channel.name, msg.message);
                                                             
                                                             if ( [[[NSString stringWithFormat:@"%@", msg.message] substringWithRange:NSMakeRange(1,14)] isEqualToString: @"**************" ])
                                                             {
                                                                 // Bonus #1 send a goodbye message
                                                                 [PubNub sendMessage:[NSString stringWithFormat:@"Thank you, GOODBYE!" ] toChannel:myChannel withCompletionBlock:^(PNMessageState messageState, id data) {
                                                                     // Bonus #2 unsubscribe only if message is sent
                                                                     if (messageState == PNMessageSent) {
                                                                         NSLog(@"OBSERVER: Sent Goodbye Message!");
                                                                         [PubNub unsubscribeFromChannel:myChannel ];
                                                                     }
                                                                 }];
                                                             }
                                                         }];
    
    //add observer for unsubscribed event
    [[PNObservationCenter defaultCenter] addClientChannelUnsubscriptionObserver:self
                                                              withCallbackBlock:^(NSArray *channel, PNError *error) {
                                                                  if (error == nil) {
                                                                      NSLog(@"OBSERVER: Unsubscribed from Channel: %@", channel[0]);
                                                                      
                                                                      //resubscribe after unsubscribe
                                                                      [PubNub subscribeOnChannel:myChannel];
                                                                  }else {
                                                                      NSLog(@"OBSERVER: Unsubscribed from Channel: %@, Error: %@", channel[0], error);
                                                                  }
                                                              }];
    
    //add message processing observer
    [[PNObservationCenter defaultCenter] addMessageProcessingObserver:self
                                                            withBlock:^(PNMessageState state, id data) {
                                                                switch (state) {
                                                                    case PNMessageSent:
                                                                        NSLog(@"OBSERVER: Message Sent.");
                                                                        break;
                                                                    case PNMessageSending:
                                                                        NSLog(@"OBSERVER: Sending Message...");
                                                                        break;
                                                                    case PNMessageSendingError:
                                                                        NSLog(@"OBSERVER: ERROR: Failed to Send Message.");
                                                                        break;
                                                                    default:
                                                                        break;
                                                            }
                                                        }];

    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
