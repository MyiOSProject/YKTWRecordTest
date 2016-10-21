//
//  ViewController.m
//  YKTWRecordTest
//
//  引用第三方库lame进行mp3格式类型转换
//  Created by qianjianlei on 16/10/20.
//  Copyright © 2016年 钱建磊. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "lame.h"

@interface ViewController ()<AVAudioPlayerDelegate>
{
    CGPoint _tempPoint;
    
    NSURL *_recordUrl;
    AVAudioRecorder *_audioRecorder;
    NSInteger _endState; // 0：取消  1：发送
    NSURL *mp3Path;
    AVAudioPlayer *player;
    NSString *_recording;
}

@end

@implementation ViewController

- (IBAction)record:(UIButton *)sender {
    if (![_recording isEqualToString:@"T"]) {
        //开始录制
        NSLog(@"===开始录制====");
        [_recordButton setTitle: @"录音结束" forState: UIControlStateNormal];
        _recording = @"T";
        [_audioRecorder record];
    }else{
        //结束录制
        [_recordButton setTitle: @"开始录音" forState: UIControlStateNormal];
        NSLog(@"===结束录制====FilePath:%@",_recordUrl);
        _recording = @"F";
        [_audioRecorder stop];
    }
}
- (IBAction)play:(UIButton *)sender {
    NSError *playerError;
    player = nil;
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:mp3Path error:&playerError];
    
    if (player == nil)
    {
        NSLog(@"ERror creating player: %@", [playerError description]);
    }else{
        [player play];
        NSLog(@"=========播放文件路径:%@",mp3Path);
    }
}
- (IBAction)exchange2mp3:(UIButton *)sender {
    mp3Path = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"record.mp3"]];
    
    NSString *s1=[[_recordUrl absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    s1 = [s1 substringFromIndex:7];
    const char *c1 = [s1 UTF8String];
    
    NSString *s2=[[mp3Path absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    s2 = [s2 substringFromIndex:7];
    const char *c2 = [s2 UTF8String];
    
    NSLog(@"==c1:%s======c2:%s",c1,c2);
    
    @try {
        int read, write;
        
        FILE *pcm = fopen(c1, "rb");  //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen(c2, "wb");  //output 输出生成的Mp3文件位置
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 11025.0);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        do {
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {
        NSLog(@"MP3生成成功: %@",mp3Path);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _recording = @"F";
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *sessionError;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:11025.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    
    
    _recordUrl = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"record.caf"]];
    NSError *error;
    
    NSLog(@"====_recordUrl=====:%@",_recordUrl);
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:_recordUrl settings:recordSetting error:&error];
    _audioRecorder.meteringEnabled = YES;
    
    // 长按录音
    UILongPressGestureRecognizer *presss = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.recordButton addGestureRecognizer:presss];
}
- (void)longPress:(UILongPressGestureRecognizer *)press {
    switch (press.state) {
        case UIGestureRecognizerStateBegan : {
            NSLog(@"began");
            [_audioRecorder record];
            
            break;
        }
        case UIGestureRecognizerStateChanged: {
            NSLog(@"change;");
            
            CGPoint point = [press locationInView:self.view];
            if (point.y < _tempPoint.y - 10) {
                _endState = 0;
//                _yinjieBtn.hidden = YES;
//                _label.text = @"松开手指，取消发送";
//                _label.backgroundColor = [UIColor clearColor];
//                _imgView.image = [UIImage imageNamed:@"chexiao"];
                
                if (!CGPointEqualToPoint(point, _tempPoint) && point.y < _tempPoint.y - 8) {
                    _tempPoint = point;
                }
            } else if (point.y > _tempPoint.y + 10) {
                _endState = 1;
//                _centerX.constant = -20;
//                _yinjieBtn.hidden = NO;
//                _label.backgroundColor = [UIColor redColor];
//                _label.text = @"手指上滑，取消发送";
//                _imgView.image = [UIImage imageNamed:@"yuyin"];
                if (!CGPointEqualToPoint(point, _tempPoint) && point.y > _tempPoint.y + 8) {
                    _tempPoint = point;
                }
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            NSLog(@"cancel, end");
            [self endPress];
            [_audioRecorder stop];
            break;
        }
        case UIGestureRecognizerStateFailed: {
            NSLog(@"failed");
            break;
        }
        default: {
            break;
        }
    }
}

- (void)endPress {
    switch (_endState) {
        case 0: {
            NSLog(@"取消发送");
            break;
        }
        case 1: {
            NSLog(@"发送");
            break;
        }
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
