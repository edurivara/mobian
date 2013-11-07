//
//  mbnViewController.m
//  Mobian
//
//  Created by Eduardo Rivara on 11/6/13.
//  Copyright (c) 2013 Eduardo Rivara. All rights reserved.
//

#import "mbnViewController.h"
#import "RIOInterface.h"
#import "KeyHelper.h"

@interface mbnViewController ()

@property NSMutableArray *soundsArray;
@property int posicionLetra;
@property AVAudioPlayer *player;


@end


@implementation mbnViewController

//Listener
@synthesize palabraDetectada;
@synthesize listenButton;
@synthesize key;
@synthesize isListening;
@synthesize	rioRef;
@synthesize currentFrequency;
@synthesize lastCapture;
@synthesize isParsing;

//player
@synthesize soundsArray;
@synthesize posicionLetra;
@synthesize timeStarted;
@synthesize palabra;
@synthesize tiempoEntreFonemas;
@synthesize toneUnit;
@synthesize frequency;
@synthesize sampleRate;
@synthesize theta;



//SoundPlayer
@synthesize soundPlayerStart;
@synthesize soundPlayerEnd;

//**********Player**********

OSStatus RenderTone(
                    void *inRefCon,
                    AudioUnitRenderActionFlags 	*ioActionFlags,
                    const AudioTimeStamp 		*inTimeStamp,
                    UInt32 						inBusNumber,
                    UInt32 						inNumberFrames,
                    AudioBufferList 			*ioData)

{
	// Get the tone parameters out of the view controller
    mbnViewController *viewController =
    (__bridge mbnViewController *)inRefCon;
    
    //Tiempo entre fonemas
    const double tiempoEntreFonemas = [viewController.tiempoEntreFonemas floatValue];
    
	// Fixed amplitude is good enough for our purposes
	const double amplitude = 0.5;
    
    
    //Controlo el tiempo para parar
    if (!viewController.timeStarted) viewController.timeStarted = [NSDate date];
    NSTimeInterval timeElapsed = -[viewController.timeStarted timeIntervalSinceNow];
    
    //Calcula la letra a emitir
    int posicionLetra = floor(timeElapsed/tiempoEntreFonemas);
    float tiempoDesdeNuevaLetra = ((timeElapsed/tiempoEntreFonemas)-floor(timeElapsed/tiempoEntreFonemas));
    
    //Si termino la palabra salgo
    if (posicionLetra > [viewController.palabra.text length]){
        viewController->frequency = 0;
        [viewController performSelectorOnMainThread:@selector(stop) withObject:nil waitUntilDone:NO];
        [viewController.soundPlayerEnd play];
    }
    
    if (tiempoDesdeNuevaLetra>tiempoEntreFonemas/6){
        //Obtengo la letra
        NSString *letra = [[NSString alloc] initWithFormat:@"%c",[viewController.palabra.text characterAtIndex:posicionLetra]];
        
        //Calcula la frecuencia para esa letra
        KeyHelper *helper = [KeyHelper sharedInstance];
        NSNumber *frequencia = [helper frequencyForChar:letra];
        
        //Seteo la frecuencia
        viewController->frequency = [frequencia floatValue];
    }else{
        viewController->frequency = 0;
    }
    
    double theta = viewController->theta;
	double theta_increment = 2.0 * M_PI * viewController->frequency / viewController->sampleRate;
    
	// This is a mono tone generator so we only need the first buffer
	const int channel = 0;
	Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
	
	// Generate the samples
	for (UInt32 frame = 0; frame < inNumberFrames; frame++)
	{
		buffer[frame] = sin(theta) * amplitude;
		
		theta += theta_increment;
		if (theta > 2.0 * M_PI)
		{
			theta -= 2.0 * M_PI;
		}
	}
	
	// Store the theta back in the view controller
	viewController->theta = theta;
    
	return noErr;
}

void ToneInterruptionListener(void *inClientData, UInt32 inInterruptionState)
{
	mbnViewController *viewController =
    (__bridge mbnViewController *)inClientData;
	
	[viewController stop];
}

- (IBAction)say:(id)sender {
    
    [palabra resignFirstResponder];
    
    //Play start sound
    [soundPlayerStart play];
    //Cuando termina de tocar el sonido va a la funcion delegada y continua con la palabra.
    
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{

    if (player == soundPlayerStart){
        
        if ((!toneUnit)&&flag){
        
            self.timeStarted = [NSDate date];
            [self createToneUnit];
            // Stop changing parameters on the unit
            OSErr err = AudioUnitInitialize(toneUnit);
            NSAssert1(err == noErr, @"Error initializing unit: %d", err);
            // Start playback
            err = AudioOutputUnitStart(toneUnit);
            NSAssert1(err == noErr, @"Error starting unit: %d", err);
		
        }
    }
}


- (void)createToneUnit
{
	// Configure the search parameters to find the default playback output unit
	// (called the kAudioUnitSubType_RemoteIO on iOS but
	// kAudioUnitSubType_DefaultOutput on Mac OS X)
	AudioComponentDescription defaultOutputDescription;
	defaultOutputDescription.componentType = kAudioUnitType_Output;
	defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
	defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	defaultOutputDescription.componentFlags = 0;
	defaultOutputDescription.componentFlagsMask = 0;
	
	// Get the default playback output unit
	AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
	NSAssert(defaultOutput, @"Can't find default output");
	
	// Create a new unit based on this that we'll use for output
	OSErr err = AudioComponentInstanceNew(defaultOutput, &toneUnit);
	NSAssert1(toneUnit, @"Error creating unit: %d", err);
	
	// Set our tone rendering function on the unit
	AURenderCallbackStruct input;
	input.inputProc = RenderTone;
	input.inputProcRefCon = (__bridge void *)(self);
	err = AudioUnitSetProperty(toneUnit,
                               kAudioUnitProperty_SetRenderCallback,
                               kAudioUnitScope_Input,
                               0,
                               &input,
                               sizeof(input));
	NSAssert1(err == noErr, @"Error setting callback: %d", err);
	
	// Set the format to 32 bit, single channel, floating point, linear PCM
	const int four_bytes_per_float = 4;
	const int eight_bits_per_byte = 8;
	AudioStreamBasicDescription streamFormat;
	streamFormat.mSampleRate = sampleRate;
	streamFormat.mFormatID = kAudioFormatLinearPCM;
	streamFormat.mFormatFlags =
    kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
	streamFormat.mBytesPerPacket = four_bytes_per_float;
	streamFormat.mFramesPerPacket = 1;
	streamFormat.mBytesPerFrame = four_bytes_per_float;
	streamFormat.mChannelsPerFrame = 1;
	streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
	err = AudioUnitSetProperty (toneUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                0,
                                &streamFormat,
                                sizeof(AudioStreamBasicDescription));
	NSAssert1(err == noErr, @"Error setting stream format: %d", err);
}


- (void)stop
{
	if (toneUnit)
	{
		AudioOutputUnitStop(toneUnit);
		AudioUnitUninitialize(toneUnit);
		AudioComponentInstanceDispose(toneUnit);
		toneUnit = nil;
		
	}
}




//**********Listener**********


- (IBAction)toggleListening:(id)sender {
	if (isListening) {
		[self stopListener];
		[listenButton setTitle:@"Begin Listening" forState:UIControlStateNormal];
	} else {
		[self startListener];
		[listenButton setTitle:@"Stop Listening" forState:UIControlStateNormal];
	}
	
}

- (void)startListener {
	[rioRef startListening:self];
    isListening = true;
}

- (void)stopListener {
	[rioRef stopListening];
    isListening = false;
}

// Este metodo lo llama el Listener cuando cambia la frecuencia
- (void)frequencyChangedWithValue:(float)newFrequency{

    NSTimeInterval timeInterval = -[lastCapture timeIntervalSinceNow];
    
    if ((timeInterval>([tiempoEntreFonemas floatValue]*3))&&isParsing){
        //empieza palabra nueva
        key = nil;
        [self performSelectorInBackground:@selector(updateKeyLabel) withObject:@"argh"];
        isParsing = FALSE;
    }

    
	if ((newFrequency>1200)&(newFrequency<1300)) isParsing = TRUE;
    
	if (((newFrequency>2450)&(newFrequency<3900)) && isParsing){
        
        if ((timeInterval>=[tiempoEntreFonemas floatValue])||!key){
            
            KeyHelper *helper = [KeyHelper sharedInstance];
            NSArray *closestArray = [helper closestCharForFrequency:newFrequency];
            NSString *closestChar = [closestArray objectAtIndex:0];
            NSNumber *proximity = [closestArray objectAtIndex:1];
            
            if ([proximity floatValue] < 20){
                
                lastCapture = [NSDate date];
                if (!key)
                    key = [NSMutableString stringWithFormat:@"%@", closestChar];
                else
                    key = [NSMutableString stringWithFormat:@"%@", [self.key stringByAppendingString:closestChar]];
                
                self.currentFrequency = newFrequency;
                
                [self performSelectorInBackground:@selector(updateKeyLabel) withObject:nil];
                
            }
        }
        
        
    }
}

//Key tiene la palabra que detecto el Listener
- (void)updateKeyLabel {
	palabraDetectada.text = [NSString stringWithFormat:@"%@", key];
	[palabraDetectada setNeedsDisplay];
}






//**********GENERAL**********

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Listener
	rioRef = [RIOInterface sharedInstance];
    lastCapture = [NSDate date];
    isParsing = FALSE;
    
    //Player
    palabra.delegate = self;
    sampleRate = 44100;
    frequency = 440;
    tiempoEntreFonemas = @0.15;
    
    //Wav Player
    NSString *soundFilePath = [[NSBundle mainBundle] pathForResource: @"startsound" ofType: @"wav"];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
    AVAudioPlayer *newPlayerStart = [[AVAudioPlayer alloc] initWithContentsOfURL: fileURL error: nil];
    soundPlayerStart = newPlayerStart;
    soundPlayerStart.delegate = self;
    [soundPlayerStart prepareToPlay];

    soundFilePath = [[NSBundle mainBundle] pathForResource: @"endsound" ofType: @"wav"];
    fileURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
    AVAudioPlayer *newPlayerEnd = [[AVAudioPlayer alloc] initWithContentsOfURL: fileURL error: nil];
    soundPlayerEnd = newPlayerEnd;
    [soundPlayerEnd prepareToPlay];
    
    /* LO COMENTE DESPUES DEL ERROR AL INICIALIZAR REMOTEIO
     OSStatus result = AudioSessionInitialize(NULL, NULL, ToneInterruptionListener, (__bridge void *)(self));
     if (result == kAudioSessionNoError)
     {
     UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
     AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
     }
     AudioSessionSetActive(true);
     
     */
    [self startListener];
    
    
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	palabraDetectada = nil;
    listenButton = nil;
	AudioSessionSetActive(false);
    
    [super viewDidUnload];
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField resignFirstResponder];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}



@end
