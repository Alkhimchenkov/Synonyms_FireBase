//
//  ApiData.h
//  Synonyms
//
//  Created by Андрей on 24.06.17.
//  Copyright © 2017 Home. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ApiData : NSObject

@property (strong, nonatomic) NSDictionary *dataRequest;


-(BOOL)requestFromServer:(NSURL*)urlString;
+(NSURL*)getUrl:(NSString*)word;
-(void)updateFireBase:(NSString*)key data:(NSArray*)data;
-(void)setDataFromFireBase;

@end
