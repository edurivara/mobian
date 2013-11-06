//
//  mbnViewController.h
//  Mobian
//
//  Created by Eduardo Rivara on 11/6/13.
//  Copyright (c) 2013 Eduardo Rivara. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class RIOInterface;

@interface mbnViewController : UIViewController <AVAudioPlayerDelegate, UITextFieldDelegate>

//Listener
@property (weak, nonatomic) IBOutlet UIButton *listenButton;
@property (weak, nonatomic) IBOutlet UILabel *palabraDetectada;
@property(nonatomic, weak) NSMutableString *key;
@property(nonatomic, unsafe_unretained) RIOInterface *rioRef;
@property(nonatomic, assign) float currentFrequency;
@property(assign) BOOL isListening;
@property(weak, nonatomic) NSDate *lastCapture;


//Player
@property(strong, nonatomic) NSDate *timeStarted;
@property (strong, nonatomic) IBOutlet UITextField *palabra;
@property (strong, nonatomic) NSNumber *tiempoEntreFonemas;
@property AudioComponentInstance toneUnit;
@property (assign) double frequency;
@property (assign) double sampleRate;
@property (assign) double theta;


//Listener
- (IBAction)toggleListening:(id)sender;
- (void)startListener;
- (void)stopListener;
- (void)frequencyChangedWithValue:(float)newFrequency;

//Player
- (void)stop;

@end
