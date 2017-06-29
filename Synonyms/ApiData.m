//
//  ApiData.m
//  Synonyms
//
//  Created by Андрей on 24.06.17.
//  Copyright © 2017 Home. All rights reserved.
//

#import "ApiData.h"
#import "DataProvider.h"

@import FirebaseDatabase;


static NSString *const kApiLinkWord  = @"http://words.bighugelabs.com/api/2";
static NSString *const kApikey = @"878a9a751f0764ed2d800b6f4bf70303";
static NSString *const kApiTypeResult = @"json";

@interface ApiData ()

@property (strong, nonatomic) FIRDatabaseReference *ref;

@end


@implementation ApiData

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dataRequest = nil;
        _ref = [[FIRDatabase database] reference];
    }
    return self;
}


-(BOOL)requestFromServer:(NSURL*)urlString{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlString];
    [request setHTTPMethod:@"GET"];
    NSData *data = [ApiData sendSynchronousRequest:request];
    if (data) {
        self.dataRequest = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        return YES;
    }
    return NO;
}

+(NSURL*)getUrl:(NSString*)word {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@/%@",kApiLinkWord, kApikey, word, kApiTypeResult]];
}


-(void)setDataFromFireBase{
    [[_ref child:@"syn"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        if (![snapshot.value isKindOfClass:[NSNull class]]) {
            NSArray *keys = [snapshot.value allKeys];
            for (NSString *key in keys) {
                NSMutableArray *wordArray = [[NSMutableArray alloc] init];
                [wordArray addObjectsFromArray:snapshot.value[key]];
                [[DataProvider sharedInstance] addSaveData:@[@{key:wordArray}]];
            }
        }
    }];
//    [[_ref child:@"syn"] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
//        if (![snapshot.value isKindOfClass:[NSNull class]]) {
//            NSArray *keys = [snapshot.value allKeys];
//            for (NSString *key in keys) {
//                NSMutableArray *wordArray = [[NSMutableArray alloc] init];
//                [wordArray addObjectsFromArray:snapshot.value[key]];
//                [[DataProvider sharedInstance] addSaveData:@[@{key:wordArray}]];
//            }
//        }
//    }];
}


-(void)updateFireBase:(NSString*)key data:(NSArray*)data{
    NSDictionary *childUpdates = @{[@"/syn/" stringByAppendingString:key ]: data};
    [self.ref updateChildValues:childUpdates];
}


+(NSData*)sendSynchronousRequest:(NSURLRequest*)request{
    
    dispatch_semaphore_t sem;
    
    __block NSData *result;
    
    result = nil;
    
    sem = dispatch_semaphore_create(0);
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                         
                                         if (error) {
                                             //  NSLog(@"dataTaskWithRequest errors: %@", error);
                                             return;
                                         }
                                         
                                         if ([response isKindOfClass:[NSHTTPURLResponse class]]){
                                             NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
                                            
                                             if (statusCode == 200)
                                                 result = data;
                                             
                                         }
                                         
                                         dispatch_semaphore_signal(sem);
                                     }] resume];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return result;
}


@end
