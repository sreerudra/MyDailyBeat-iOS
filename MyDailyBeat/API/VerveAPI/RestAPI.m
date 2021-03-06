//
//  API.m
//  VerveAPI
//
//  Created by Virinchi Balabhadrapatruni on 8/17/14.
//  Copyright (c) 2014 eVerveCorp. All rights reserved.
//

#import "RestAPI.h"



@implementation RestAPI

static VerveUser *currentUser;

+(id)getInstance {
    static RestAPI *api = nil;
    static dispatch_once_t initApi;
    dispatch_once(&initApi, ^{
        api = [[self alloc] init];
    });
    return api;
}

- (id)init {
    if (self = [super init]) {
        currentUser = nil;
    }
    return self;
}

- (BOOL) loginWithScreenName:(NSString *) screenName andPassword:(NSString *) password {
    @try {
        
        NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
        [postData setObject:screenName forKey:@"screenName"];
        [postData setObject:password forKey:@"password"];
        
        NSError *error;
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
        
        if (error) {
            NSLog(@"Error parsing object to JSON: %@", error);
        }
        
        NSDictionary *resultDic = [self makeRequestWithBaseUrl:PUBLIC_BASE_URL withPath:@"login" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        
        if ([resultDic objectForKey:@"token"] != nil) {
            currentUser = [[VerveUser alloc] init];
            currentUser.name = [resultDic objectForKey:@"name"];
            currentUser.email = [resultDic objectForKey:@"email"];
            currentUser.screenName = screenName;
            currentUser.password = password;
            currentUser.mobile = [resultDic objectForKey:@"mobile"];
            currentUser.zipcode = [resultDic objectForKey:@"zipcode"];
            currentUser.birth_month = [resultDic objectForKey:@"birth_month"];
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            currentUser.birth_year = [[f numberFromString:[resultDic objectForKey:@"birth_year"]] longValue];
            currentUser.birth_date = [[f numberFromString:[resultDic objectForKey:@"birth_date"]] longValue];
            currentUser.auth_token = [resultDic objectForKey:@"token"];
            
            return YES;
        }
        
        return NO;

        
    } @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    
    return NO;
}

- (BOOL) logout {
    currentUser.auth_token = nil;
    return YES;
}

- (void) refreshCurrentUserData {
    NSString *parameters = [@"token=" stringByAppendingString:currentUser.auth_token];
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:AUTH_BASE_URL withPath:@"users/get" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    if ([resultDic objectForKey:@"screenName"] != nil) {
        currentUser.name = [resultDic objectForKey:@"name"];
        currentUser.email = [resultDic objectForKey:@"email"];
        currentUser.screenName = [resultDic objectForKey:@"screenName"];
        currentUser.password = [resultDic objectForKey:@"password"];
        currentUser.mobile = [resultDic objectForKey:@"mobile"];
        currentUser.zipcode = [resultDic objectForKey:@"zipcode"];
        currentUser.birth_month = [resultDic objectForKey:@"birth_month"];
        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        currentUser.birth_year = [[f numberFromString:[resultDic objectForKey:@"birth_year"]] longValue];
        currentUser.birth_date = [[f numberFromString:[resultDic objectForKey:@"birth_date"]] longValue];
        
    }
    
}

- (BOOL) sendReferralFromUser: (VerveUser *) user toPersonWithName: (NSString *) name andEmail: (NSString *) email {
    @try {
        
        NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
        [postData setObject:user.auth_token forKey:@"token"];
        [postData setObject:name forKey:@"name"];
        [postData setObject:email forKey:@"email"];
        
        NSError *error;
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
        
        if (error) {
            NSLog(@"Error parsing object to JSON: %@", error);
        }
        
        NSDictionary *resultDic = [self makeRequestWithBaseUrl:AUTH_BASE_URL withPath:@"refer/send" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        
        if (resultDic == nil) {
            return NO;
        }
        return YES;
        
        
    } @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    
    return NO;
}

- (NSMutableDictionary *) getOpportunitiesInLocation: (NSString *) zipcode onPage: (int) page {
    NSMutableDictionary *arr = [[NSMutableDictionary alloc] init];
    NSString *params = [NSString stringWithFormat:@"page=%d&zip=%@&token=%@", page, zipcode, currentUser.auth_token];
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:AUTH_BASE_URL withPath:@"volunteering/search" withParameters:params withRequestType:GET_REQUEST andPostData:nil];
    NSString *json = [resultDic objectForKey:@"jsonString"];
    json = json.stringByRemovingPercentEncoding;
    json = [json stringByReplacingOccurrencesOfString:@"\\" withString:@""];
    NSRange range = [json rangeOfString:@"{"];
    if (range.location != NSNotFound) {
        json = [json substringFromIndex:range.location];
    } else {
        NSLog(@"Error: Malformed Result: %@", json);
    }
    NSLog(@"%@", json);
    NSDictionary *temp = [NSDictionary dictionaryFromString:json options:NSJSONReadingMutableContainers];
    arr = [[NSMutableDictionary alloc] initWithDictionary:temp];
    
    return arr;
}

- (NSMutableArray *) getPostsForGroup:(Group *) g {
    NSString *parameters = [NSString stringWithFormat:@"token=%@", currentUser.auth_token];
    NSString *path = [NSString stringWithFormat:@"groups/%d/posts/get", g.groupID];
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:AUTH_BASE_URL withPath:path withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    
    NSMutableArray *items = [resultDic objectForKey:@"items"];
    NSMutableArray *retItems = [[NSMutableArray alloc] init];
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    
    for (int i= 0 ; i < [items count] ; ++i) {
        Post *p = [[Post alloc] init];
        NSDictionary *post = [items objectAtIndex:i];
        p.postText = [post objectForKey:@"postText"];
        p.blobKey = [post objectForKey:@"blobKey"];
        p.servingURL = [post objectForKey:@"servingURL"];
        p.userScreenName = [post objectForKey:@"userScreenName"];
        p.post_id = [[post objectForKey:@"id"] intValue];
        p.dateTimeMillis = [[f numberFromString:[post objectForKey:@"when"]] longLongValue];
        [retItems addObject:p];
    }
    
    
    return retItems;
    
}

- (BOOL) createUser: (VerveUser *) userData {
    
    @try {
        
        NSMutableDictionary *postData = [userData toJSON];
        
        NSError *error;
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
        
        if (error) {
            NSLog(@"Error parsing object to JSON: %@", error);
        }
        
        NSDictionary *result = [self makeRequestWithBaseUrl:PUBLIC_BASE_URL withPath:@"users/register" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        NSLog(@"%@", result);
        if (result == nil) {
            return NO;
        }
        
        return YES;
        
    } @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    
    return NO;
}

- (BOOL) doesUserExistWithName: (NSString *) name {
    NSString *parameters = [@"name=" stringByAppendingString:[self urlencode:name]];
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:BASE_URL withPath:@"users/exists/name" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    
    NSString *response = [resultDic objectForKey:@"response"];
    if ([response isEqualToString:@"Operation succeeded"]) {
        return NO;
    }
    return YES;
    
}

- (BOOL) doesUserExistWithScreenName: (NSString *) screenName {
    NSString *parameters = [@"screenName=" stringByAppendingString:[self urlencode:screenName]];
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:BASE_URL withPath:@"users/exists/screenName" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    
    NSString *response = [resultDic objectForKey:@"response"];
    if ([response isEqualToString:@"Operation succeeded"]) {
        return NO;
    }
    return YES;

}
- (BOOL) doesUserExistWithEmail:(NSString *)email {
    NSString *parameters = [@"email=" stringByAppendingString:[self urlencode:email]];
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:BASE_URL withPath:@"users/exists/email" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    
    NSString *response = [resultDic objectForKey:@"response"];
    if ([response isEqualToString:@"Operation succeeded"]) {
        return NO;
    }
    return YES;
}
- (BOOL) doesUserExistWithMobile:(NSString *)mobile {
    NSString *parameters = [@"mobile=" stringByAppendingString:[self urlencode:mobile]];
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:BASE_URL withPath:@"users/exists/mobile" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    
    NSString *response = [resultDic objectForKey:@"response"];
    if ([response isEqualToString:@"Operation succeeded"]) {
        return NO;
    }
    return YES;
}

- (BOOL) editUser: (VerveUser *) userData {
    
    @try {
        
        NSMutableDictionary *postData = [userData toJSON];
        
        NSError *error;
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
        
        if (error) {
            NSLog(@"Error parsing object to JSON: %@", error);
        }
        
        NSDictionary *result = [self makeRequestWithBaseUrl:BASE_URL withPath:@"users/edit" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        
        NSString *response = [result objectForKey:@"response"];
        if ([response isEqualToString:@"Operation succeeded"]) {
            return YES;
        }
        
    } @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    
    return NO;
}

- (VerveUserPreferences *) getUserPreferencesForUser: (VerveUser *) user {
    VerveUserPreferences *prefs = [[VerveUserPreferences alloc] init];
    NSString *parameters = [@"screenName=" stringByAppendingString:[self urlencode:user.screenName]];
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:BASE_URL withPath:@"preferences/user/get" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    if (resultDic != nil) {
        prefs.gender = [[resultDic objectForKey:@"gender"] intValue];
        prefs.age = [[resultDic objectForKey:@"age"] intValue];
        prefs.status = [[resultDic objectForKey:@"status"] intValue];
        prefs.ethnicity = [[resultDic objectForKey:@"ethnicity"] intValue];
        prefs.beliefs = [[resultDic objectForKey:@"beliefs"] intValue];
        prefs.contact = [[resultDic objectForKey:@"contact"] intValue];
        prefs.drinker = [[resultDic objectForKey:@"drinker"] intValue];
        prefs.smoker = [[resultDic objectForKey:@"smoker"] boolValue];
        prefs.veteran = [[resultDic objectForKey:@"veteran"] boolValue];
        prefs.feelingBlue = [[resultDic objectForKey:@"feelingBlue"] boolValue];
        prefs.otherEthnicity = (NSString *) [resultDic objectForKey:@"otherEthnicity"];
        prefs.otherBeliefs = (NSString *) [resultDic objectForKey:@"otherBeliefs"];
        
    }

    return prefs;
}
- (VerveMatchingPreferences *) getMatchingPreferencesForUser: (VerveUser *) user {
    VerveMatchingPreferences *prefs = [[VerveMatchingPreferences alloc] init];
    NSString *parameters = [@"screenName=" stringByAppendingString:[self urlencode:user.screenName]];
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:BASE_URL withPath:@"preferences/matching/get" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    if (resultDic != nil) {
        prefs.gender = [[resultDic objectForKey:@"gender"] intValue];
        prefs.age = [[resultDic objectForKey:@"age"] intValue];
        prefs.status = [[resultDic objectForKey:@"status"] intValue];
        prefs.ethnicity = [[resultDic objectForKey:@"ethnicity"] intValue];
        prefs.beliefs = [[resultDic objectForKey:@"beliefs"] intValue];
        prefs.drinker = [[resultDic objectForKey:@"drinker"] intValue];
        prefs.smoker = [[resultDic objectForKey:@"smoker"] boolValue];
        prefs.veteran = [[resultDic objectForKey:@"veteran"] boolValue];
        
    }
    
    return prefs;
}

- (BOOL) saveUserPreferences: (VerveUserPreferences *) preferences forUser: (VerveUser *) user {
    @try {
        
        NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
        [postData setObject:currentUser.screenName forKey:@"screenName"];
        
        [postData setObject:[preferences toJSON] forKey:@"prefs"];
        
        NSError *error;
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
        
        if (error) {
            NSLog(@"Error parsing object to JSON: %@", error);
        }
        
        NSDictionary *result = [self makeRequestWithBaseUrl:BASE_URL withPath:@"preferences/user/save" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        
        NSString *response = [result objectForKey:@"response"];
        if ([response isEqualToString:@"Operation succeeded"]) {
            return YES;
        }
        
    } @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    
    return NO;
}
- (BOOL) saveMatchingPreferences: (VerveMatchingPreferences *) matchingPreferences forUser: (VerveUser *) user {
    @try {
        
        NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
        [postData setObject:currentUser.screenName forKey:@"screenName"];
        
        [postData setObject:[matchingPreferences toJSON] forKey:@"matchingPrefs"];
        
        NSError *error;
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
        
        if (error) {
            NSLog(@"Error parsing object to JSON: %@", error);
        }
        
        NSDictionary *result = [self makeRequestWithBaseUrl:BASE_URL withPath:@"preferences/matching/save" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        
        NSString *response = [result objectForKey:@"response"];
        if ([response isEqualToString:@"Operation succeeded"]) {
            return YES;
        }
        
    } @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    
    return NO;
}
- (BOOL) saveUserPreferences: (VerveUserPreferences *) preferences andMatchingPreferences: (VerveMatchingPreferences *) matchingPreferences forUser: (VerveUser *) user {
    @try {
        
        NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
        [postData setObject:currentUser.screenName forKey:@"screenName"];
        [postData setObject:currentUser.password forKey:@"password"];
        
        [postData setObject:[preferences toJSON] forKey:@"prefs"];
        [postData setObject:[matchingPreferences toJSON] forKey:@"matchingPrefs"];
        
        NSError *error;
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
        
        if (error) {
            NSLog(@"Error parsing object to JSON: %@", error);
        }
        
        NSDictionary *result = [self makeRequestWithBaseUrl:BASE_URL withPath:@"preferences/save" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        
        NSString *response = [result objectForKey:@"response"];
        if ([response isEqualToString:@"Operation succeeded"]) {
            return YES;
        }
        
    } @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    
    return NO;
}

- (BOOL) setHobbiesforGroup: (Group *) group {
    @try {
        
        NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
        [postData setObject:[NSNumber numberWithInt:group.groupID] forKey:@"id"];
        [postData setObject:group.hobbies forKey:@"hobbies"];
        
        NSError *error;
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
        
        if (error) {
            NSLog(@"Error parsing object to JSON: %@", error);
        }
        
        NSDictionary *result = [self makeRequestWithBaseUrl:BASE_URL withPath:@"groups/edit" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        
        NSString *response = [result objectForKey:@"response"];
        if ([response isEqualToString:@"Operation succeeded"]) {
            return YES;
        }
        
    } @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    
    return NO;
}

-(NSURL *) retrieveProfilePicture {
    return [self retrieveProfilePictureForUserWithScreenName:currentUser.screenName];
}

-(NSURL *) retrieveProfilePictureForUserWithScreenName:(NSString *) screenName{
    NSString *parameters = [@"screen_name=" stringByAppendingString:[self urlencode:screenName]];
    NSDictionary *getServingURLResult = [self makeRequestWithBaseUrl:BASE_URL withPath:@"users/profile/blobkey/retrieve" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    NSString *s = [getServingURLResult objectForKey:@"servingURL"];
    if (s == nil) {
        return nil;
    }
    NSURL *url = [[NSURL alloc] initWithString:s];
    return url;
}

-(BOOL) uploadProfilePicture:(NSData *)profilePicture withName: (NSString *) name {
    
    //start by getting upload url
    NSDictionary *getURLResult = [self makeRequestWithBaseUrl:BASE_URL withPath:@"users/getuploadurl" withParameters:@"" withRequestType:GET_REQUEST andPostData:nil];
    NSString *uploadurl = [getURLResult objectForKey:@"response"];
    
    AFHTTPRequestSerializer *ser = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request = [ser multipartFormRequestWithMethod:POST_REQUEST URLString:uploadurl parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:profilePicture name:@"file" fileName:name mimeType:[self getMimeType:name]];
        
        [formData appendPartWithFormData:[[name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLUserAllowedCharacterSet]] dataUsingEncoding:NSUTF8StringEncoding] name:@"name"];
    } error:nil];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:YES];
    [request setTimeoutInterval:30];
    NSLog(@"%@", request);
    // send the request
    __block NSError *requestError = nil;
    __block BOOL returnVal = NO;
    __block NSDictionary *parsedJSONResponse = nil;
    NSURLSession *session = [NSURLSession sharedSession];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) NSLog(@"Error received from server: %@", error);
        if (((NSHTTPURLResponse *) response).statusCode >= 200 && ((NSHTTPURLResponse *) response).statusCode < 300) {
            parsedJSONResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&requestError];
        } else if (((NSHTTPURLResponse *) response).statusCode == 401) {
            NSLog(@"Unauthorized. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else if (((NSHTTPURLResponse *) response).statusCode == 422) {
            NSLog(@"Unprocessable entity. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else if (((NSHTTPURLResponse *) response).statusCode == 500) {
            NSLog(@"Internal server error. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else if (((NSHTTPURLResponse *) response).statusCode == 404) {
            NSLog(@"Not found. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else {
            NSLog(@"Unrecognized status code = %ld. %@", (long)((NSHTTPURLResponse *) response).statusCode, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }
        
        dispatch_semaphore_signal(semaphore);
        
    }];
    
    [task resume];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    if (parsedJSONResponse != nil) {
        NSString *blobKey = [parsedJSONResponse objectForKey:@"blobKey"];
        NSString *servingURL = [parsedJSONResponse objectForKey:@"servingUrl"];
        
        NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
        [postData setObject:blobKey forKey:@"blobKey"];
        [postData setObject:servingURL forKey:@"servingURL"];
        [postData setObject:currentUser.screenName forKey:@"screenName"];
        [postData setObject:currentUser.password forKey:@"password"];
        
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&requestError];
        
        NSDictionary *result = [self makeRequestWithBaseUrl:BASE_URL withPath:@"users/profile/blobkey/save" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        
        NSString *response = [result objectForKey:@"response"];
        if ([response isEqualToString:@"Operation succeeded"]) {
            returnVal = YES;
        } else {
            returnVal =  NO;
        }

    } else {
        returnVal = NO;
    }

    return returnVal;
}

-(NSURL *) retrieveGroupPictureForGroup:(Group *) group {
    NSString *parameters = [NSString stringWithFormat:@"id=%d", group.groupID];
    NSDictionary *getServingURLResult = [self makeRequestWithBaseUrl:BASE_URL withPath:@"groups/blobkey/retrieve" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    NSString *s = [getServingURLResult objectForKey:@"servingURL"];
    if (s == nil) {
        return nil;
    }
    group.servingURL = s;
    group.blobKey = [getServingURLResult objectForKey:@"blobKey"];
    NSURL *url = [[NSURL alloc] initWithString:s];
    return url;
    
}

-(BOOL) writePost:(Post *) p withPictureData:(NSData *) attachedPic andPictureName:(NSString *) picName toGroup:(Group *) g {
    
    NSError *requestError;
    
    if (attachedPic != nil) {
        NSDictionary *getURLResult = [self makeRequestWithBaseUrl:BASE_URL withPath:@"users/getuploadurl" withParameters:@"" withRequestType:GET_REQUEST andPostData:nil];
        NSString *uploadurl = [getURLResult objectForKey:@"response"];
        
        AFHTTPRequestSerializer *ser = [AFHTTPRequestSerializer serializer];
        NSMutableURLRequest *request = [ser multipartFormRequestWithMethod:POST_REQUEST URLString:uploadurl parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:attachedPic name:@"file" fileName:picName mimeType:[self getMimeType:picName]];
            [formData appendPartWithFormData:[[picName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLUserAllowedCharacterSet]] dataUsingEncoding:NSUTF8StringEncoding] name:@"name"];
        } error:nil];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        [request setHTTPShouldHandleCookies:YES];
        [request setTimeoutInterval:30];
        NSLog(@"%@", request);
        // send the request
        
        __block NSError *requestError = nil;
        __block BOOL returnVal = NO;
        __block NSDictionary *parsedJSONResponse = nil;
        NSURLSession *session = [NSURLSession sharedSession];
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) NSLog(@"Error received from server: %@", error);
            if (((NSHTTPURLResponse *) response).statusCode >= 200 && ((NSHTTPURLResponse *) response).statusCode < 300) {
                parsedJSONResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&requestError];
                
            } else if (((NSHTTPURLResponse *) response).statusCode == 401) {
                NSLog(@"Unauthorized. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            } else if (((NSHTTPURLResponse *) response).statusCode == 422) {
                NSLog(@"Unprocessable entity. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            } else if (((NSHTTPURLResponse *) response).statusCode == 500) {
                NSLog(@"Internal server error. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            } else if (((NSHTTPURLResponse *) response).statusCode == 404) {
                NSLog(@"Not found. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            } else {
                NSLog(@"Unrecognized status code = %ld. %@", (long)((NSHTTPURLResponse *) response).statusCode, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            }
            
            dispatch_semaphore_signal(semaphore);
            
        }];
        
        [task resume];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        if (parsedJSONResponse != nil) {
            NSString *blobKey = [parsedJSONResponse objectForKey:@"blobKey"];
            NSString *servingURL = [parsedJSONResponse objectForKey:@"servingUrl"];
            
            NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
            [postData setObject:blobKey forKey:@"blobKey"];
            [postData setObject:servingURL forKey:@"servingURL"];
            [postData setObject:p.postText forKey:@"postText"];
            [postData setObject:p.userScreenName forKey:@"userScreenName"];
            [postData setObject:[NSNumber numberWithLongLong:p.dateTimeMillis] forKey:@"when"];
            [postData setObject:[NSNumber numberWithInt:g.groupID] forKey:@"id"];
            
            NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&requestError];
            
            
            NSDictionary *result = [self makeRequestWithBaseUrl:BASE_URL withPath:@"groups/post" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
            
            NSString *response = [result objectForKey:@"response"];
            if ([response isEqualToString:@"Operation succeeded"]) {
                returnVal = YES;
            } else {
                returnVal = NO;
            }
        } else {
            returnVal = NO;
        }
        
        return returnVal;

    } else {
        NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
        [postData setObject:@"" forKey:@"blobKey"];
        [postData setObject:@"" forKey:@"servingURL"];
        [postData setObject:p.postText forKey:@"postText"];
        [postData setObject:p.userScreenName forKey:@"userScreenName"];
        [postData setObject:[NSNumber numberWithDouble:p.dateTimeMillis] forKey:@"when"];
        [postData setObject:[NSNumber numberWithInt:g.groupID] forKey:@"id"];
        
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&requestError];
        
        
        NSDictionary *result = [self makeRequestWithBaseUrl:BASE_URL withPath:@"groups/post" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        
        NSString *response = [result objectForKey:@"response"];
        if ([response isEqualToString:@"Operation succeeded"]) {
            return YES;
        } else
            return NO;
        
    }
    return NO;
}

-(BOOL)uploadGroupPicture:(NSData *)groupPicture withName: (NSString *) name toGroup:(Group *) group {
    
    //start by getting upload url
    NSDictionary *getURLResult = [self makeRequestWithBaseUrl:BASE_URL withPath:@"users/getuploadurl" withParameters:@"" withRequestType:GET_REQUEST andPostData:nil];
    NSString *uploadurl = [getURLResult objectForKey:@"response"];
    
    AFHTTPRequestSerializer *ser = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request = [ser multipartFormRequestWithMethod:POST_REQUEST URLString:uploadurl parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:groupPicture name:@"file" fileName:name mimeType:[self getMimeType:name]];
        [formData appendPartWithFormData:[[name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLUserAllowedCharacterSet]] dataUsingEncoding:NSUTF8StringEncoding] name:@"name"];
    } error:nil];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:YES];
    [request setTimeoutInterval:30];
    NSLog(@"%@", request);
    // send the request
    
    __block NSError *requestError = nil;
    __block BOOL returnVal = NO;
    __block NSDictionary *parsedJSONResponse = nil;
    NSURLSession *session = [NSURLSession sharedSession];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) NSLog(@"Error received from server: %@", error);
        if (((NSHTTPURLResponse *) response).statusCode >= 200 && ((NSHTTPURLResponse *) response).statusCode < 300) {
            parsedJSONResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&requestError];
        } else if (((NSHTTPURLResponse *) response).statusCode == 401) {
            NSLog(@"Unauthorized. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else if (((NSHTTPURLResponse *) response).statusCode == 422) {
            NSLog(@"Unprocessable entity. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else if (((NSHTTPURLResponse *) response).statusCode == 500) {
            NSLog(@"Internal server error. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else if (((NSHTTPURLResponse *) response).statusCode == 404) {
            NSLog(@"Not found. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else {
            NSLog(@"Unrecognized status code = %ld. %@", (long)((NSHTTPURLResponse *) response).statusCode, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }
        
        dispatch_semaphore_signal(semaphore);
        
    }];
    
    [task resume];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    if (parsedJSONResponse != nil) {
        NSString *blobKey = [parsedJSONResponse objectForKey:@"blobKey"];
        NSString *servingURL = [parsedJSONResponse objectForKey:@"servingUrl"];
        
        NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
        [postData setObject:blobKey forKey:@"blobKey"];
        [postData setObject:servingURL forKey:@"servingURL"];
        [postData setObject:[NSNumber numberWithInt:group.groupID] forKey:@"id"];
        
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&requestError];
        
        NSDictionary *result = [self makeRequestWithBaseUrl:BASE_URL withPath:@"groups/blobkey/save" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        
        NSString *response = [result objectForKey:@"response"];
        if ([response isEqualToString:@"Operation succeeded"]) {
            returnVal = YES;
        } else {
           returnVal = NO;
        }
        
    } else {
        returnVal = NO;
    }
    
    return returnVal;
    
}


-(NSString *)getMimeType:(NSString *)path{
    CFStringRef pathExtension = (__bridge_retained CFStringRef)[path pathExtension];
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, NULL);
    // The UTI can be converted to a mime type:
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType);
    return mimeType;
}

- (NSDictionary *) searchUsersWithQueryString:(NSString *) query andQueryType:(UserSearchType) type withSortOrder:(EVCSearchSortOrder) sortOrder {
    NSString *parameters = [@"query=" stringByAppendingString:[self urlencode:query]];
    parameters = [parameters stringByAppendingString:[@"&sort_order=" stringByAppendingString:[NSString stringWithFormat:@"%d", sortOrder]]];
    
    switch (type) {
        case SearchByScreenName: {
            return [self makeRequestWithBaseUrl:BASE_URL withPath:@"users/search/screenName" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
        }
            break;
            
        case SearchByEmail: {
            return [self makeRequestWithBaseUrl:BASE_URL withPath:@"users/search/email" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
        }
            break;
            
        case SearchByName: {
            return [self makeRequestWithBaseUrl:BASE_URL withPath:@"users/search/name" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
        }
            break;
    }
}

- (NSDictionary *) searchGroupsWithQueryString:(NSString *) query withSortOrder:(EVCSearchSortOrder) sortOrder {
    NSString *parameters = [@"query=" stringByAppendingString:[self urlencode:query]];
    parameters = [parameters stringByAppendingString:[@"&sort_order=" stringByAppendingString:[NSString stringWithFormat:@"%d", sortOrder]]];
    return [self makeRequestWithBaseUrl:BASE_URL withPath:@"groups/search" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
}

- (VerveBankObject *) getBankInfoForBankWithName: (NSString *) name inCountry: (NSString *) country {
    NSString *parameters = [@"term=" stringByAppendingString:[self urlencode:name]];
    parameters = [parameters stringByAppendingString:@"&country="];
    parameters = [parameters stringByAppendingString:[self urlencode:country]];
    parameters = [parameters stringByAppendingString:@"&media=software&entity=software&attribute=softwareDeveloper"];
    parameters = [parameters stringByAppendingString:@"&limit=200"];
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:@"https://itunes.apple.com" withPath:@"search" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    NSArray *results = [resultDic objectForKey:@"results"];
    NSDictionary *bankDic = [results objectAtIndex:0];
    VerveBankObject *bankObj = [[VerveBankObject alloc] init];
    bankObj.uniqueID = [[bankDic objectForKey:@"trackId"] intValue];
    bankObj.appName = [bankDic objectForKey:@"trackCensoredName"];
    bankObj.appStoreListing = [bankDic objectForKey:@"trackViewUrl"];
    bankObj.appIconURL = [bankDic objectForKey:@"artworkUrl512"];
    
    return bankObj;
}

- (BOOL) doesAppExistWithTerm: (NSString *) name andCountry: (NSString *) country {
    
    NSString *parameters = [@"term=" stringByAppendingString:[self urlencode:name]];
    parameters = [parameters stringByAppendingString:@"&country="];
    parameters = [parameters stringByAppendingString:[self urlencode:country]];
    parameters = [parameters stringByAppendingString:@"&media=software&entity=software&attribute=softwareDeveloper"];
    parameters = [parameters stringByAppendingString:@"&limit=200"];
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:@"https://itunes.apple.com" withPath:@"search" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    NSString *count = [resultDic objectForKey:@"resultCount"];
    if ([count intValue] < 1) {
        return false;
    }
    return true;
}

- (HobbiesPreferences *) getHobbiesPreferencesForUserWithScreenName: (NSString *) screenName {
    NSString *parameters = [@"screenName=" stringByAppendingString:[self urlencode:screenName]];
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:BASE_URL withPath:@"prefs/hobbies/get" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    NSMutableArray *list = [resultDic objectForKey:@"hobbyList"];
    return [HobbiesPreferences fromJSON:list];
}
- (BOOL) saveHobbiesPreferences: (HobbiesPreferences *) prefs forUserWithScreenName: (NSString *) screenName {
    @try {
        NSMutableArray *array = [HobbiesPreferences toJSON:prefs];
        NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
        [postData setObject:array forKey:@"hobbyList"];
        [postData setObject:screenName forKey:@"screenName"];
        NSError *error;
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
        
        if (error) {
            NSLog(@"Error parsing object to JSON: %@", error);
        }
        
        NSDictionary *result = [self makeRequestWithBaseUrl:BASE_URL withPath:@"prefs/hobbies/save" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        
        
        NSString *response = [result objectForKey:@"response"];
        if ([response isEqualToString:@"Operation succeeded"]) {
            return YES;
        }
        
    } @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    
    return NO;
}

- (NSMutableArray *) getHobbiesMatchesForUserWithScreenName:(NSString *) screenName {
    NSString *parameters = [@"screenName=" stringByAppendingString:[self urlencode:screenName]];
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:BASE_URL withPath:@"hobbies/match" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    
    NSMutableArray *items = [resultDic objectForKey:@"items"];
    NSMutableArray *retItems = [[NSMutableArray alloc] init];
    
    for (int i= 0 ; i < [items count] ; ++i) {
        HobbiesMatchObject *match = [[HobbiesMatchObject alloc] init];
        NSDictionary *item = [items objectAtIndex:i];
        NSDictionary *prefs = [item objectForKey:@"prefs"];
        match.prefs = [HobbiesPreferences fromJSON:[prefs objectForKey:@"hobbyList"]];
        NSDictionary *userDic = [item objectForKey:@"userObj"];
        VerveUser *temp = [[VerveUser alloc] init];
        temp.screenName = [userDic objectForKey:@"screenName"];
        match.userObj = temp;
        [retItems addObject:match];
    }
    
    return retItems;
}

- (NSMutableArray *) getGroupsForCurrentUser {
    return [self getGroupsForUser:currentUser];
}

- (NSMutableArray *) getGroupsForUser:(VerveUser *) user {
    NSString *parameters = [@"screen_name=" stringByAppendingString:[self urlencode:user.screenName]];
    parameters = [parameters stringByAppendingString:[@"&password=" stringByAppendingString:[self urlencode:user.password]]];
    
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:BASE_URL withPath:@"groups/get" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    
    NSMutableArray *items = [resultDic objectForKey:@"items"];
    NSMutableArray *retItems = [[NSMutableArray alloc] init];
    
    for (int i= 0 ; i < [items count] ; ++i) {
        Group *g = [[Group alloc] init];
        NSDictionary *item = [items objectAtIndex:i];
        g.groupName = [item objectForKey:@"groupName"];
        g.adminName = [item objectForKey:@"adminScreenName"];
        g.blobKey = [item objectForKey:@"blobKey"];
        g.servingURL = [item objectForKey:@"servingURL"];
        g.groupID = [[item objectForKey:@"id"] intValue];
        NSMutableArray *postJSON = [item objectForKey:@"posts"];
        NSMutableArray *posts = [[NSMutableArray alloc] init];
        for (int j=0 ; j < [postJSON count] ; ++j) {
            Post *p = [[Post alloc] init];
            NSDictionary *post = [postJSON objectAtIndex:j];
            p.postText = [post objectForKey:@"postText"];
            p.blobKey = [post objectForKey:@"blobKey"];
            p.servingURL = [post objectForKey:@"servingURL"];
            p.post_id = [[post objectForKey:@"id"] intValue];
            p.userScreenName = [post objectForKey:@"userScreenName"];
            p.dateTimeMillis = [[post objectForKey:@"when"] longLongValue];
            [posts addObject:p];
        }
        g.posts = posts;
        NSMutableArray *hobbies = [item objectForKey:@"hobbies"];
        g.hobbies = hobbies;
        [retItems addObject:g];
    }
    
    
    return retItems;
}

- (NSMutableArray *) getPlacesWithType: (NSString *) searchType withName: (NSString *) name andCategory: (NSString *) category fromLocation: (CLLocationCoordinate2D) coordinate {
    NSString *baseurl = @"https://maps.googleapis.com";
    NSString *path = @"maps/api/place/radarsearch/json";
    NSString *parameters = @"";
    if ([searchType isEqualToString:@"name"] ) {
        parameters = [NSString stringWithFormat:@"keyword=%@", [self urlencode:name]];
    } else if ([searchType isEqualToString:@"category"]) {
        parameters = [NSString stringWithFormat:@"types=%@", category];
    }
    
    parameters = [parameters stringByAppendingString:@"&radius=50000"];
    parameters = [parameters stringByAppendingString:[NSString stringWithFormat:@"&location=%f,%f", (double)coordinate.latitude, (double) coordinate.longitude]];
    
    parameters = [parameters stringByAppendingString:[NSString stringWithFormat:@"&key=%@", PLACES_API_KEY]];
    
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:baseurl withPath:path withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    
    return [resultDic objectForKey:@"results"];

}

- (NSDictionary *) getDetailsForPlaceWithID: (NSString *) placeID {
    NSString *baseurl = @"https://maps.googleapis.com";
    NSString *path = @"maps/api/place/details/json";
    NSString *parameters = [NSString stringWithFormat:@"placeid=%@&key=%@", placeID, PLACES_API_KEY];
    
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:baseurl withPath:path withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    
    return [resultDic objectForKey:@"result"];
    
}

- (NSMutableArray *) getGeocodesForPlaces: (NSArray *) places {
    NSMutableArray *outP = [[NSMutableArray alloc] init];
    NSString *baseurl = @"https://maps.googleapis.com";
    NSString *path = @"maps/api/geocode/json";
    
    for (int i = 0; i < [places count]; i++) {
        
        VerveVolunteering *v = [places objectAtIndex:i];
        NSString *address = v.address;
        address = [address stringByAppendingString:@", "];
        address = [address stringByAppendingString:v.city];
        address = [address stringByAppendingString:@", "];
        address = [address stringByAppendingString:v.state];
        
        NSString *parameters = [NSString stringWithFormat:@"address=%@&key=%@", [self urlencode:address], PLACES_API_KEY];
        NSDictionary *resultDic = [self makeRequestWithBaseUrl:baseurl withPath:path withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
        NSDictionary *geo = [resultDic objectForKey:@"geometry"];
        NSDictionary *loc = [geo objectForKey:@"location"];
        MapPoint *pnt = [[MapPoint alloc] initWithName:v.npName address:address coordinate:CLLocationCoordinate2DMake([[loc objectForKey:@"lat"] doubleValue], [[loc objectForKey:@"lng"] doubleValue])];
        
        v.pnt = pnt;
        [outP addObject:v];

        
    }
    
    return outP;
}

- (NSArray *) getVolunteeringList {
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:BASE_URL withPath:@"volunteering/get" withParameters:nil withRequestType:GET_REQUEST andPostData:nil];
    NSArray *arr = [resultDic objectForKey:@"items"];
    NSMutableArray *outA = [[NSMutableArray alloc] init];
    for (int i = 0; i < [arr count]; i++) {
        NSDictionary *item = [arr objectAtIndex:i];
        VerveVolunteering *v = [[VerveVolunteering alloc] init];
        v.npName = [item objectForKey:@"npName"];
        v.address = [item objectForKey:@"address"];
        v.category = [item objectForKey:@"category"];
        v.city = [item objectForKey:@"city"];
        v.state = [item objectForKey:@"state"];
        v.zipcode = [item objectForKey:@"zipcode"];
        [outA addObject:v];
    }
    
    return outA;
}

- (BOOL) saveVolunteeringList:(NSArray *)arr {
    
    @try {
        
        NSMutableArray *items = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < [arr count]; i++) {
            NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
            VerveVolunteering *v = [arr objectAtIndex:i];
            [item setObject:v.npName forKey:@"npName"];
            [item setObject:v.address forKey:@"address"];
            [item setObject:v.category forKey:@"category"];
            [item setObject:v.city forKey:@"city"];
            [item setObject:v.state forKey:@"state"];
            [item setObject:v.zipcode forKey:@"zipcode"];
            [items addObject:item];
        }
        
        NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
        [postData setObject:items forKey:@"items"];
        NSError *error;
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
        
        if (error) {
            NSLog(@"Error parsing object to JSON: %@", error);
        }
        
        NSDictionary *result = [self makeRequestWithBaseUrl:BASE_URL withPath:@"volunteering/save" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        
        
        NSString *response = [result objectForKey:@"response"];
        if ([response isEqualToString:@"Operation succeeded"]) {
            return YES;
        }
        
    } @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    
    return NO;
}

- (BOOL) createGroupWithName:(NSString *) groupName {
    
    
    @try {
        
        NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
        [postData setObject:currentUser.screenName forKey:@"screenName"];
        [postData setObject:currentUser.password forKey:@"password"];
        [postData setObject:groupName forKey:@"groupName"];
        NSError *error;
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
        
        if (error) {
            NSLog(@"Error parsing object to JSON: %@", error);
        }
        
        NSDictionary *result = [self makeRequestWithBaseUrl:BASE_URL withPath:@"groups/create" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        
        
        NSString *response = [result objectForKey:@"response"];
        if ([response isEqualToString:@"Operation succeeded"]) {
            return YES;
        }
        
    } @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    
    return NO;
}

- (BOOL) joinGroupWithName:(NSString *) groupName {
    @try {
        
        NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
        [postData setObject:currentUser.screenName forKey:@"screenName"];
        [postData setObject:currentUser.password forKey:@"password"];
        [postData setObject:groupName forKey:@"groupName"];
        NSError *error;
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
        
        if (error) {
            NSLog(@"Error parsing object to JSON: %@", error);
        }
        
        NSDictionary *result = [self makeRequestWithBaseUrl:BASE_URL withPath:@"users/groups/join" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        
        
        NSString *response = [result objectForKey:@"response"];
        if ([response isEqualToString:@"Operation succeeded"]) {
            return YES;
        }
        
    } @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    
    return NO;
    
}

- (BOOL) deletePost:(Post *) p {
    NSString *parameters = [@"id=" stringByAppendingString:[NSString stringWithFormat:@"%d", p.post_id]];
    
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:BASE_URL withPath:@"groups/posts/delete" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    
    NSString *response = [resultDic objectForKey:@"response"];
    if ([response isEqualToString:@"Operation succeeded"]) {
        return YES;
    }
    
    return NO;
    
}

- (BOOL) deleteGroup:(Group *) g {
    NSString *parameters = [@"id=" stringByAppendingString:[NSString stringWithFormat:@"%d", g.groupID]];
    
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:BASE_URL withPath:@"groups/delete" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    
    NSString *response = [resultDic objectForKey:@"response"];
    if ([response isEqualToString:@"Operation succeeded"]) {
        return YES;
    }
    
    return NO;
    
}

- (BOOL) inviteUser:(VerveUser *) invitee toJoinGroup:(Group *) groupOfChoice by:(EVCUserInviteSendingMethod) method withMessage:(NSString *) inviteMessage {
    switch (method) {
        case SendByEmail:
            @try {
                
                NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
                [postData setObject:currentUser.email forKey:@"senderemail"];
                [postData setObject:invitee.email forKey:@"recipientemail"];
                [postData setObject:inviteMessage forKey:@"inviteMessage"];
                [postData setObject:[NSNumber numberWithInt:groupOfChoice.groupID] forKey:@"groupID"];
                
                NSError *error;
                NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
                
                if (error) {
                    NSLog(@"Error parsing object to JSON: %@", error);
                }
                
                NSDictionary *result = [self makeRequestWithBaseUrl:BASE_URL withPath:@"groups/invite/email" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
                
                
                NSString *response = [result objectForKey:@"response"];
                if ([response isEqualToString:@"Operation succeeded"]) {
                    return YES;
                }
                
            } @catch (NSException *e) {
                NSLog(@"%@", e);
            }
            
            break;
        case SendByMobile:
            //send by mobile
            NSLog(@"Not implemented yet due to logistical issues");
            break;
    }
    
    return NO;
}

- (BOOL) writeMessage:(NSString *) message asUser:(VerveUser *) user inChatRoomWithID: (int) chatID atTime: (long long) dateTimeMillis {
    
    @try {
        NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
        [postData setObject:user.screenName forKey:@"screenName"];
        [postData setObject:message forKey:@"messageText"];
        [postData setObject:[NSNumber numberWithLongLong:dateTimeMillis] forKey:@"dateTimeMillis"];
        [postData setObject:[NSNumber numberWithInt:chatID] forKey:@"chatID"];
        
        NSError *error;
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
        
        if (error) {
            NSLog(@"Error parsing object to JSON: %@", error);
        }
        
        NSDictionary *result = [self makeRequestWithBaseUrl:BASE_URL withPath:@"fling/messaging/post" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        
        
        NSString *response = [result objectForKey:@"response"];
        if ([response isEqualToString:@"Operation succeeded"]) {
            return YES;
        }
        
    } @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    
    return NO;
}

- (MessageChatroom *) createChatroomForUsersWithScreenName: (NSString *) firstUser andScreenName: (NSString *) secondUser {
    @try {
        NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
        [postData setObject:firstUser forKey:@"screenName1"];
        [postData setObject:secondUser forKey:@"screenName2"];
        
        NSError *error;
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
        
        if (error) {
            NSLog(@"Error parsing object to JSON: %@", error);
        }
        
        NSDictionary *result = [self makeRequestWithBaseUrl:BASE_URL withPath:@"fling/messaging/newchatroom" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        
        
        MessageChatroom *m = [[MessageChatroom alloc] init];
        
        if ([result objectForKey:@"screenNames"] != nil) {
            m.chatroomID = [[result objectForKey:@"CHATROOM_ID"] intValue];
            m.screenNames = [result objectForKey:@"screenNames"];
            m.messages = [result objectForKey:@"messages"];
            return m;
        }
        
        
        
        
    } @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    
    return nil;
}

- (NSArray *) getChatroomsForUser: (VerveUser *) user {
    NSString *parameters = [@"screenName=" stringByAppendingString:[self urlencode:user.screenName]];
    
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:BASE_URL withPath:@"fling/messaging/getchatrooms" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    
    NSMutableArray *items = [resultDic objectForKey:@"items"];
    NSMutableArray *retItems = [[NSMutableArray alloc] init];
    
    for (int i= 0 ; i < [items count] ; ++i) {
        MessageChatroom *m = [[MessageChatroom alloc] init];
        NSDictionary *item = [items objectAtIndex:i];
        m.chatroomID = [[item objectForKey:@"CHATROOM_ID"] intValue];
        m.screenNames = [item objectForKey:@"screenNames"];
        m.messages = [item objectForKey:@"messages"];
        
        [retItems addObject:m];
    }
    
    
    return retItems;
    
}

- (NSArray *) getFlingProfilesBasedOnPrefsOfUser:(VerveUser *) user {
    NSString *parameters = [@"screen_name=" stringByAppendingString:[self urlencode:user.screenName]];
    parameters = [parameters stringByAppendingString:[@"&password=" stringByAppendingString:[self urlencode:user.password]]];
    
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:BASE_URL withPath:@"relationship/match" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    
    NSMutableArray *items = [resultDic objectForKey:@"items"];
    NSMutableArray *retItems = [[NSMutableArray alloc] init];
    NSLog(@"Matches: %lu", (unsigned long)[items count]);
    for (int i = 0 ; i < [items count] ; ++i) {
        
        NSDictionary *item = [items objectAtIndex:i];
        FlingProfile *prof = [[FlingProfile alloc] init];
        
        prof.screenName = [item objectForKey:@"screenName"];
        prof.aboutMe = [ item objectForKey:@"aboutMe"];
        
        [retItems addObject:prof];
    }
    
    return retItems;
    
    
}

- (NSArray *) getFriendsForUser: (VerveUser *) user {
    NSString *parameters = [@"screen_name=" stringByAppendingString:[self urlencode:user.screenName]];
    
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:BASE_URL withPath:@"friends/get" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    
    NSMutableArray *items = [resultDic objectForKey:@"items"];
    NSMutableArray *retItems = [[NSMutableArray alloc] init];
    
    for (int i = 0 ; i < [items count] ; ++i) {
        NSDictionary *item = [items objectAtIndex:i];
        FlingProfile *prof = [[FlingProfile alloc] init];
        
        prof.screenName = [item objectForKey:@"screenName"];
        prof.aboutMe = [ item objectForKey:@"aboutMe"];
        
        [retItems addObject:prof];
    }
    
    return retItems;
    
}
- (BOOL) addUser:(VerveUser *) user1 ToFriendsOfUser:(VerveUser *) user2 {
    @try {
        NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
        [postData setObject:user2.screenName forKey:@"screenName"];
        [postData setObject:[self getFlingProfileForUser:user1] forKey:@"other"];
        
        NSError *error;
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
        
        if (error) {
            NSLog(@"Error parsing object to JSON: %@", error);
        }
        
        NSDictionary *result = [self makeRequestWithBaseUrl:BASE_URL withPath:@"friends/add" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        
        
        NSString *response = [result objectForKey:@"response"];
        if ([response isEqualToString:@"Operation succeeded"]) {
            return YES;
        }
        
    } @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    
    return NO;
    
}

- (NSArray *) getFlingFavoritesForUser: (VerveUser *) user {
    NSString *parameters = [@"screen_name=" stringByAppendingString:[self urlencode:user.screenName]];
    
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:BASE_URL withPath:@"fling/favorites/get" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    
    NSMutableArray *items = [resultDic objectForKey:@"items"];
    NSMutableArray *retItems = [[NSMutableArray alloc] init];
    
    for (int i = 0 ; i < [items count] ; ++i) {
        NSDictionary *item = [items objectAtIndex:i];
        FlingProfile *prof = [[FlingProfile alloc] init];
        
        prof.screenName = [item objectForKey:@"screenName"];
        prof.aboutMe = [ item objectForKey:@"aboutMe"];
        
        [retItems addObject:prof];
    }
    
    return retItems;
    
}
- (BOOL) addUser:(VerveUser *) user1 ToFlingFavoritesOfUser:(VerveUser *) user2 {
    @try {
        NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
        [postData setObject:user2.screenName forKey:@"screenName"];
        [postData setObject:[self getFlingProfileForUser:user1] forKey:@"other"];
        
        NSError *error;
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
        
        if (error) {
            NSLog(@"Error parsing object to JSON: %@", error);
        }
        
        NSDictionary *result = [self makeRequestWithBaseUrl:BASE_URL withPath:@"fling/favorites/add" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        
        
        NSString *response = [result objectForKey:@"response"];
        if ([response isEqualToString:@"Operation succeeded"]) {
            return YES;
        }
        
    } @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    
    return NO;
    
}

- (FlingProfile *) getFlingProfileForUser:(VerveUser *) user {
    NSString *parameters = [@"screenName=" stringByAppendingString:[self urlencode:user.screenName]];
    
    
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:BASE_URL withPath:@"fling/profile/get" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    
    
    FlingProfile *prof = [[FlingProfile alloc] init];
    
    prof.screenName = [resultDic objectForKey:@"screenName"];
    prof.aboutMe = [resultDic objectForKey:@"aboutMe"];
    
    return prof;
    
    
}

- (BOOL) saveFlingProfileForUser:(VerveUser *) user withAge: (int) age andDescription:(NSString *) about andInterests: (NSArray *) array {
    
    @try {
        NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
        [postData setObject:user.screenName forKey:@"screenName"];
        [postData setObject:about forKey:@"aboutMe"];
        [postData setObject:[NSNumber numberWithInt:age] forKey:@"age"];

        
        NSError *error;
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
        
        if (error) {
            NSLog(@"Error parsing object to JSON: %@", error);
        }
        
        NSDictionary *result = [self makeRequestWithBaseUrl:BASE_URL withPath:@"fling/profile/save" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        
        
        NSString *response = [result objectForKey:@"response"];
        if ([response isEqualToString:@"Operation succeeded"]) {
            return YES;
        }
        
    } @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    
    return NO;
    
}

- (MessageChatroom *) getChatroomByID: (int) ID {
    NSString *parameters = [NSString stringWithFormat:@"id=%d", ID];
    
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:BASE_URL withPath:@"fling/messaging/getchatroomsbyid" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    
    MessageChatroom *m = [[MessageChatroom alloc] init];
    m.chatroomID = [[resultDic objectForKey:@"CHATROOM_ID"] intValue];
    m.screenNames = [resultDic objectForKey:@"screenNames"];
    m.messages = [resultDic objectForKey:@"messages"];
    
    return m;

}

- (NSArray *) getMessagesForChatroomWithID: (int) ID {
    NSString *parameters = [NSString stringWithFormat:@"id=%d", ID];
    
    NSDictionary *resultDic = [self makeRequestWithBaseUrl:BASE_URL withPath:@"fling/messaging/getmessages" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
    
    NSMutableArray *items = [resultDic objectForKey:@"items"];
    NSMutableArray *retItems = [[NSMutableArray alloc] init];
    
    for (int i = 0 ; i < [items count] ; ++i) {
        NSDictionary *item = [items objectAtIndex:i];
        VerveMessage *prof = [[VerveMessage alloc] init];
        
        prof.screenName = [item objectForKey:@"screenName"];
        prof.message = [item objectForKey:@"messageText"];
        
        [retItems addObject:prof];
    }
    
    return retItems;

}


/*
 * Returns the current saved user object.
 *
 * @return A VerveUser object that corresponds to the owner of the current session
 */
-(VerveUser *)getCurrentUser {
    return currentUser;
}

+(BOOL)hasConnectivity {
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    return !(networkStatus == NotReachable);
}

- (NSDictionary *) searchShoppingURLSWithQueryString: (NSString *) query withSortOrder: (EVCSearchSortOrder) sortOrder {
        NSString *parameters = [@"query=" stringByAppendingString:[self urlencode:query]];
        parameters = [parameters stringByAppendingString:[@"&sort_order=" stringByAppendingString:[NSString stringWithFormat:@"%d", sortOrder]]];
        return [self makeRequestWithBaseUrl:BASE_URL withPath:@"shopping/url/search" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
}

- (NSDictionary *) getShoppingFavoritesForUser: (VerveUser *) user withSortOrder: (EVCSearchSortOrder) sortOrder {
    NSString *parameters = [@"screen_name=" stringByAppendingString:[self urlencode:user.screenName]];
    return [self makeRequestWithBaseUrl:BASE_URL withPath:@"shopping/url/favorites/get" withParameters:parameters withRequestType:GET_REQUEST andPostData:nil];
}

- (BOOL) addShoppingFavoriteURL: (NSString * ) string ForUser: (VerveUser *) user {
    @try {
        NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
        [postData setObject:user.screenName forKey:@"screenName"];
        [postData setObject:string forKey:@"url"];
        
        NSError *error;
        NSData *postReqData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
        
        if (error) {
            NSLog(@"Error parsing object to JSON: %@", error);
        }
        
        NSDictionary *result = [self makeRequestWithBaseUrl:BASE_URL withPath:@"shopping/url/favorites/add" withParameters:@"" withRequestType:POST_REQUEST andPostData:postReqData];
        
        
        NSString *response = [result objectForKey:@"response"];
        if ([response isEqualToString:@"Operation succeeded"]) {
            return YES;
        }
        
    } @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    
    return NO;
}

- (NSDictionary *) getUsersForFeelingBlue {
    
    return [self makeRequestWithBaseUrl:BASE_URL withPath:@"feelingblue/anonymous/load" withParameters:nil withRequestType:GET_REQUEST andPostData:nil];
}

/**
 * Makes an HTTP request for JSON-formatted data. Functions that
 * call this function should not be run on the UI thread.
 *
 * @param baseUrl The base of the URL to which the request will be made
 * @param path The path to append to the request URL
 * @param parameters Parameters separated by ampersands (&)
 * @param reqType The request type as a string (i.e. GET or POST)
 * @param postData The data to be given to MyDailyBeat as NSData
 * @return An object dump of a JSONObject or JSONArray representing the requested data
 */
-(id)makeRequestWithBaseUrl:(NSString *)baseUrl withPath:(NSString *)path withParameters:(NSString *)parameters withRequestType:(NSString *)reqType andPostData:(NSData *)postData {
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/%@?%@", baseUrl, path, parameters]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:30];
    [request setHTTPMethod:reqType];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    if (postData) {
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postData.length] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:postData];
    }
    __block NSError *requestError = nil;
    NSURLSession *session = [NSURLSession sharedSession];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block id parsedJSONResponse = nil;
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) NSLog(@"Error received from server: %@", requestError);
        if (((NSHTTPURLResponse *) response).statusCode >= 200 && ((NSHTTPURLResponse *) response).statusCode < 300) {
            parsedJSONResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&requestError];
        } else if (((NSHTTPURLResponse *) response).statusCode == 401) {
            NSLog(@"Unauthorized. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else if (((NSHTTPURLResponse *) response).statusCode == 422) {
            NSLog(@"Unprocessable entity. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else if (((NSHTTPURLResponse *) response).statusCode == 500) {
            NSLog(@"Internal server error. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else if (((NSHTTPURLResponse *) response).statusCode == 404) {
            NSLog(@"Not found. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else {
            NSLog(@"Unrecognized status code = %ld. %@", (long)((NSHTTPURLResponse *) response).statusCode, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }
        
        dispatch_semaphore_signal(semaphore);
        
    }];
    
    [task resume];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return parsedJSONResponse;
}

-(id)makeXMLRequestWithBaseUrl:(NSString *)baseUrl withPath:(NSString *)path withParameters:(NSString *)parameters withRequestType:(NSString *)reqType andPostData:(NSData *)postData {
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/%@?%@", baseUrl, path, parameters]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:30];
    [request setHTTPMethod:reqType];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    if (postData) {
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postData.length] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:postData];
    }
    __block NSError *requestError = nil;
    NSURLSession *session = [NSURLSession sharedSession];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    XMLDictionaryParser *parser = [[XMLDictionaryParser alloc] init];
    __block id parsedJSONResponse = nil;
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) NSLog(@"Error received from server: %@", requestError);
        if (((NSHTTPURLResponse *) response).statusCode >= 200 && ((NSHTTPURLResponse *) response).statusCode < 300) {
            parsedJSONResponse = [parser dictionaryWithData:data];
        } else if (((NSHTTPURLResponse *) response).statusCode == 401) {
            NSLog(@"Unauthorized. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else if (((NSHTTPURLResponse *) response).statusCode == 422) {
            NSLog(@"Unprocessable entity. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else if (((NSHTTPURLResponse *) response).statusCode == 500) {
            NSLog(@"Internal server error. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else if (((NSHTTPURLResponse *) response).statusCode == 404) {
            NSLog(@"Not found. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else {
            NSLog(@"Unrecognized status code = %ld. %@", (long)((NSHTTPURLResponse *) response).statusCode, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }
        
        dispatch_semaphore_signal(semaphore);
        
    }];
    
    [task resume];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return parsedJSONResponse;
}

-(NSData *) fetchImageAtRemoteURL: (NSURL *) location {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:location
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:30];
    
    __block NSError *requestError = nil;
    NSURLSession *session = [NSURLSession sharedSession];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSData *imageData = nil;
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) NSLog(@"Error received from server: %@", requestError);
        if (((NSHTTPURLResponse *) response).statusCode >= 200 && ((NSHTTPURLResponse *) response).statusCode < 300) {
            imageData = [NSData dataWithData:data];
        } else if (((NSHTTPURLResponse *) response).statusCode == 401) {
            NSLog(@"Unauthorized. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else if (((NSHTTPURLResponse *) response).statusCode == 422) {
            NSLog(@"Unprocessable entity. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else if (((NSHTTPURLResponse *) response).statusCode == 500) {
            NSLog(@"Internal server error. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else if (((NSHTTPURLResponse *) response).statusCode == 404) {
            NSLog(@"Not found. %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else {
            NSLog(@"Unrecognized status code = %ld. %@", (long)((NSHTTPURLResponse *) response).statusCode, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }
        
        dispatch_semaphore_signal(semaphore);
    }];
    
    [task resume];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return imageData;

}

- (NSString *)urlencode: (NSString *) input {
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[input UTF8String];
    int sourceLen = (int) strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

- (NSMutableArray *) interestsJSON {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [arr addObject:@"Arts/Culture"];
    [arr addObject:@"Books"];
    [arr addObject:@"Car Enthusiast"];
    [arr addObject:@"Card Games"];
    [arr addObject:@"Dancing"];
    [arr addObject:@"Dining Out"];
    [arr addObject:@"Fitness/Wellbeing"];
    [arr addObject:@"Golf"];
    [arr addObject:@"Ladies' Night Out"];
    [arr addObject:@"Men's Night Out"];
    [arr addObject:@"Movies"];
    [arr addObject:@"Outdoor Activities"];
    [arr addObject:@"Spiritual"];
    [arr addObject:@"Baseball"];
    [arr addObject:@"Football"];
    [arr addObject:@"Hockey"];
    [arr addObject:@"Car Racing"];
    [arr addObject:@"Woodworking"];
    
    return arr;
}

@end
