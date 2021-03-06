//
//  BVQuestionSubmission.m
//  Conversations
//
//  Copyright © 2016 Bazaarvoice. All rights reserved.
//

#import "BVQuestionSubmission.h"
#import "BVQuestionSubmissionErrorResponse.h"
#import "BVSDKManager.h"
#import "BVConversationsAnalyticsUtil.h"

@interface BVQuestionSubmission()

@property (readwrite) NSString* _Nonnull productId;
@property NSMutableArray<BVUploadablePhoto*>* _Nonnull photos;
@property bool failureCalled;

@end

@implementation BVQuestionSubmission

-(nonnull instancetype)initWithProductId:(nonnull NSString*)productId {
    self = [super init];
    if(self){
        self.productId = productId;
        self.photos = [NSMutableArray array];
    }
    return self;
}

-(void)addPhoto:(nonnull UIImage*)image withPhotoCaption:(nullable NSString*)photoCaption {
    BVUploadablePhoto* photo = [[BVUploadablePhoto alloc] initWithPhoto:image photoCaption:photoCaption];
    [self.photos addObject:photo];
}


-(void)submit:(nonnull QuestionSubmissionCompletion)success failure:(nonnull ConversationsFailureHandler)failure {
    
    [BVConversationsAnalyticsUtil queueAnalyticsEventForQuestionSubmission:self];
    
    if (self.action == BVSubmissionActionPreview) {
        [[BVLogger sharedLogger] warning:@"Submitting a 'BVQuestionSubmission' with action set to `BVSubmissionActionPreview` will not actially submit the question! Set to `BVSubmissionActionSubmit` for real submission."];
        [self submitPreview:success failure:failure];
    }
    else {
        [self submitPreview:^(BVQuestionSubmissionResponse * _Nonnull response) {
            [self submitForReal:success failure:failure];
        } failure:^(NSArray<NSError *> * _Nonnull errors) {
            [self sendErrors:errors failureCallback:failure];
        }];
    }
}

-(void)submitPreview:(QuestionSubmissionCompletion)success failure:(ConversationsFailureHandler)failure {
    
    [self submitQuestionWithPhotoUrls:BVSubmissionActionPreview
                           photoUrls:@[]
                       photoCaptions:@[]
                             success:success
                             failure:failure];
    
}

-(void)submitForReal:(QuestionSubmissionCompletion)success failure:(ConversationsFailureHandler)failure {
    
    if ([self.photos count] == 0) {
        [self submitQuestionWithPhotoUrls:BVSubmissionActionSubmit
                               photoUrls:@[]
                           photoCaptions:@[]
                                 success:success
                                 failure:failure];
        return;
    }
    
    // upload photos before submitting content
    NSMutableArray<NSString*>* photoUrls = [NSMutableArray array];
    NSMutableArray<NSString*>* photoCaptions = [NSMutableArray array];
    
    for (BVUploadablePhoto* photo in self.photos) {
        
        [photo uploadForContentType:BVPhotoContentTypeQuestion success:^(NSString * _Nonnull photoUrl) {
            
            [photoUrls addObject:photoUrl];
            [photoCaptions addObject:photo.photoCaption];
            
            // all photos uploaded! submit content
            if ([photoUrls count] == [self.photos count]) {
                [self submitQuestionWithPhotoUrls:BVSubmissionActionSubmit
                                       photoUrls:photoUrls
                                   photoCaptions:photoCaptions
                                         success:success
                                         failure:failure];
            }
            
        } failure:^(NSArray<NSError *> * _Nonnull errors) {
            
            if (!self.failureCalled) {
                self.failureCalled = true; // only call failure block once, if multiple photos failed.
                
                [self sendErrors:errors failureCallback:failure];
            }
            
        }];
        
    }
    
}

-(NSData*)transformToPostBody:(NSDictionary*)dict {
    
    NSMutableArray *queryItems = [NSMutableArray array];
    
    for (NSString *key in dict) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:dict[key]]];
    }
    
    NSURLComponents *components = [NSURLComponents componentsWithString:@"http://bazaarvoice.com"];
    components.queryItems = queryItems;
    NSString* query = components.query;
    return [query dataUsingEncoding:NSUTF8StringEncoding];
    
}

-(void)submitQuestionWithPhotoUrls:(BVSubmissionAction)BVSubmissionAction photoUrls:(nonnull NSArray<NSString*>*)photoUrls photoCaptions:(nonnull NSArray<NSString*>*)photoCaptions success:(nonnull QuestionSubmissionCompletion)success failure:(nonnull ConversationsFailureHandler)failure {
    
    
    NSDictionary* parameters = [self createSubmissionParameters:BVSubmissionAction photoUrls:photoUrls photoCaptions:photoCaptions];
    NSData* postBody = [self transformToPostBody:parameters];
    
    NSString* urlString = [NSString stringWithFormat:@"%@submitquestion.json", [BVConversationsRequest commonEndpoint]];
    NSURL* url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:postBody];
    
    [[BVLogger sharedLogger] verbose:[NSString stringWithFormat:@"POST: %@\n with BODY: %@", urlString, parameters]];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *httpError) {
        
        @try {
            
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response; // This dataTask is used with only HTTP requests.
            NSInteger statusCode = httpResponse.statusCode;
            NSError* jsonParsingError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonParsingError];
            BVQuestionSubmissionErrorResponse* errorResponse = [[BVQuestionSubmissionErrorResponse alloc] initWithApiResponse:json]; // fails gracefully
            
            [[BVLogger sharedLogger] verbose:[NSString stringWithFormat:@"RESPONSE: %@ (%d)", json, statusCode]];
            
            if (httpError) {
                // network error was generated
                [self sendError:httpError failureCallback:failure];
            }
            else if(statusCode >= 300){
                // HTTP status code indicates failure
                NSError* statusError = [NSError errorWithDomain:@"com.bazaarvoice.bvsdk" code:BV_ERROR_NETWORK_FAILED userInfo:@{NSLocalizedDescriptionKey:@"Question upload failed."}];
                [self sendError:statusError failureCallback:failure];
            }
            else if (jsonParsingError) {
                // json parsing failed
                [self sendError:jsonParsingError failureCallback:failure];
            }
            else if(errorResponse){
                // api returned successfully, but has bazaarvoice-specific errors. Example: 'invalid api key'
                [self sendErrors:[errorResponse toNSErrors] failureCallback:failure];
            }
            else {
                // success!
                BVQuestionSubmissionResponse* response = [[BVQuestionSubmissionResponse alloc] initWithApiResponse:json];
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(response);
                });
            }
            
        }
        @catch (NSException *exception) {
            NSError* unexpectedError = [NSError errorWithDomain:BVErrDomain code:BV_ERROR_UNKNOWN userInfo:@{NSLocalizedDescriptionKey:@"An unknown parsing error occurred."}];
            [self sendError:unexpectedError failureCallback:failure];
        }
        
    }];
    
    // start uploading question
    [postDataTask resume];
    
}

-(nonnull NSDictionary*)createSubmissionParameters:(BVSubmissionAction)BVSubmissionAction photoUrls:(nonnull NSArray<NSString*>*)photoUrls photoCaptions:(nonnull NSArray<NSString*>*)photoCaptions {
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithDictionary:@{
                                          @"apiversion": @"5.4",
                                          @"productId": self.productId
                                       }];
    
    parameters[@"passkey"] = [BVSDKManager sharedManager].apiKeyConversations;
    parameters[@"action"] = [BVSubmissionActionUtil toString:self.action];
    
    parameters[@"questionsummary"] = self.questionSummary;
    parameters[@"questiondetails"] = self.questionDetails;
    
    parameters[@"campaignid"] = self.campaignId;
    parameters[@"locale"] = self.locale;
    parameters[@"hostedauthentication_authenticationemail"] = self.hostedAuthenticationEmail;
    parameters[@"hostedauthentication_callbackurl"] = self.hostedAuthenticationCallback;
    parameters[@"fp"] = self.fingerPrint;
    parameters[@"user"] = self.user;
    parameters[@"usernickname"] = self.userNickname;
    parameters[@"useremail"] = self.userEmail;
    parameters[@"userid"] = self.userId;
    parameters[@"userlocation"] = self.userLocation;

    if (self.isUserAnonymous) {
        parameters[@"isuseranonymous"] = [self.isUserAnonymous boolValue] ? @"true" : @"false";
    }
    
    if (self.sendEmailAlertWhenPublished) {
        parameters[@"sendemailalertwhenpublished"] = [self.sendEmailAlertWhenPublished boolValue] ? @"true" : @"false";
    }
    
    if (self.agreedToTermsAndConditions) {
        parameters[@"agreedtotermsandconditions"] = [self.agreedToTermsAndConditions boolValue] ? @"true" : @"false";
    }
    
    int photoIndex = 0;
    for(NSString* url in photoUrls) {
        NSString* key = [NSString stringWithFormat:@"photourl_%i", photoIndex];
        parameters[key] = url;
        photoIndex += 1;
    }
    
    int captionIndex = 0;
    for(NSString* caption in photoCaptions) {
        NSString* key = [NSString stringWithFormat:@"photocaption_%i", captionIndex];
        parameters[key] = caption;
        captionIndex += 1;
    }
    
    return parameters;
    
}



@end
