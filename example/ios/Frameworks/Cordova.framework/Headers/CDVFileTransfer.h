/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */


#import <Foundation/Foundation.h>
#import "CDVPlugin.h"

enum CDVFileTransferError {
	FILE_NOT_FOUND_ERR = 1,
    INVALID_URL_ERR = 2,
    CONNECTION_ERR = 3
};
typedef int CDVFileTransferError;

enum CDVFileTransferDirection {
	CDV_TRANSFER_UPLOAD = 1,
    CDV_TRANSFER_DOWNLOAD = 2,
};
typedef int CDVFileTransferDirection;

@interface CDVFileTransfer : CDVPlugin {
    
}

- (void) upload:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) download:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (NSString*) escapePathComponentForUrlString:(NSString*)urlString;

-(NSMutableDictionary*) createFileTransferError:(int)code AndSource:(NSString*)source AndTarget:(NSString*)target;

-(NSMutableDictionary*) createFileTransferError:(int)code 
                                  AndSource:(NSString*)source 
                                  AndTarget:(NSString*)target 
                                  AndHttpStatus:(int)httpStatus;
@end


@interface CDVFileTransferDelegate : NSObject {
}

@property (retain) NSMutableData* responseData; // atomic
@property (nonatomic, retain) CDVFileTransfer* command;
@property (nonatomic, assign) CDVFileTransferDirection direction;
@property (nonatomic, copy) NSString* callbackId;
@property (nonatomic, copy) NSString* source;
@property (nonatomic, copy) NSString* target;
@property (assign) int responseCode; // atomic
@property (nonatomic, assign) NSInteger bytesWritten;


@end;