//
//  main.m
//  kextstatx86
//
//  Created by Micky1979 on 06/03/16.
//  Copyright © 2016 Micky1979. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <IOKit/Kext/KextManager.h>

#include <err.h>
#include <mach/mach_error.h>

void gotoHelp(char const* self);

void gotoHelp(char const* self)
{
    assert(self);
    fprintf(stderr, "-------------------------------------------------------------\n");
    fprintf(stderr, "kextstatx86 v1.3b\n");
    fprintf(stderr, "Created by Micky1979 on 06/03/16.\n");
    fprintf(stderr, "Copyright © 2016 Micky1979 (Micky1979 at insanelymac.com). All rights reserved.\n");
    fprintf(stderr, "require 10.7+\n\n");
    
    fprintf(stderr, "Usage:\n");
    fprintf(stderr, "only one option at time allowed.\n\n");

    fprintf(stderr, "%s -h\n\tShow this message.\n\n", self);
    fprintf(stderr, "%s\n\tNo options, show info for all loaded extensions.\n\n", self);
    fprintf(stderr, "%s -l\n\tShow all prelinked extensions.\n\n", self);
    fprintf(stderr, "%s -u\n\tShow all non-prelinked extensions.\n\n", self);
    fprintf(stderr, "%s -a\n\tShow all Apple extensions.\n\n", self);
    fprintf(stderr, "%s -n\n\tShow all non-Apple extensions.\n\n", self);
    fprintf(stderr, "%s -f\n\tCreate a \"kextstatx86.plist\" on the current working directory.\n", self);
    fprintf(stderr, "-------------------------------------------------------------\n");
}

/* int main(int argc, const char * argv[]) don't want this way :-) */
int main(int argc, char* const argv[])
{
    @autoreleasepool
    {
        NSString *cmdName = [NSString stringWithFormat:@"%s" , argv[0]].lastPathComponent;
        if (![cmdName isEqualToString:@"kextstatx86"])
            errx(1,"\nError: you can't rename this command line as you wish, because of this:\n\nCreated by Micky1979 on 06/03/16.\nCopyright © 2016 Micky1979 (Micky1979 at insanelymac.com). All rights reserved.\nRename this command as \"kextstatx86\" and retry.");
        
        
        NSMutableDictionary *kexts = (__bridge NSMutableDictionary *)KextManagerCopyLoadedKextInfo(NULL, NULL);
        
        if (!kexts) errx(1,"Error: can't allocate kexts info");
        
        NSMutableDictionary *kextslist = [NSMutableDictionary dictionary];
        
        for (id obj in kexts.allKeys) {
            if ([[kexts objectForKey:obj] isKindOfClass:[NSDictionary class]]
                && ![obj isEqualToString:@"__kernel__"]
                && [[[kexts objectForKey:obj] objectForKey:@"OSBundlePath"] length] > 0)
            {
                NSString *path; // clover use "\" as separator instead of "/"
                path = [[kexts objectForKey:obj] objectForKey:@"OSBundlePath"];
                if ([path rangeOfString:@"\\"].location != NSNotFound) {
                    path = [path stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
                }
                [kextslist setObject:[kexts objectForKey:obj] forKey:[path lastPathComponent]];
            }
        }
        if (kextslist.allKeys.count < 1) errx(1,"Error: can't allocate kexts dictionary");
        
        int ch;
        int showLinked = 0;
        int showNotLinked = 0;
        int showApple = 0;
        int showNonApple = 0;
        int fullDump = 0;
        int showHelp = 0;
        
        int optCount = 0;
        while ((ch = getopt(argc, argv, "luanfh")) != -1)
            switch (ch) {
                case 'l':
                    optCount ++; showLinked    = 1;
                    break;
                case 'u':
                    optCount ++; showNotLinked = 1;
                    break;
                case 'a':
                    optCount ++; showApple     = 1;
                    break;
                case 'n':
                    optCount ++; showNonApple  = 1;
                    break;
                case 'f':
                    optCount ++; fullDump      = 1;
                    break;
                case 'h':
                    optCount ++; showHelp      = 1;
                    break;
                case '?':
                    optCount ++; showHelp      = 1;
                    break;
                default:
                    break;
            }
        
        if (optCount > 1) {
            fprintf(stderr, "-------------------------------------------------------------\n");
            printf("Error: more then one option given\n");
            gotoHelp("kextstatx86");
            exit(1);
        }
        
        if (fullDump) {
            NSString *workingDir = [[NSFileManager defaultManager] currentDirectoryPath];
            if (![kextslist writeToFile:
                  [workingDir stringByAppendingPathComponent:@"kextstatx86.plist"] atomically:YES]) {
                printf("Error: cannot write to %s\n", workingDir.UTF8String);
                exit(1);
            }
            
        }
        else
        {
            if (showLinked) {
                for (NSString* kext in kextslist.allKeys)
                {
                    if ([[[kextslist objectForKey:kext] objectForKey:@"OSBundlePrelinked"] boolValue] == YES) {
                        printf("%s (%s) %s %s\n", kext.UTF8String,
                               [[[kextslist objectForKey:kext] objectForKey:@"CFBundleVersion"] UTF8String],
                               
                               [[[kextslist objectForKey:kext] objectForKey:@"CFBundleIdentifier"] UTF8String],
                               [[[kextslist objectForKey:kext] objectForKey:@"OSBundlePath"] UTF8String]);
                    }
                }
            }
            else
                if (showNotLinked) {
                    for (NSString* kext in kextslist.allKeys)
                    {
                        if ([[[kextslist objectForKey:kext] objectForKey:@"OSBundlePrelinked"] boolValue] == NO) {
                            printf("%s (%s) %s %s\n", kext.UTF8String,
                                   [[[kextslist objectForKey:kext] objectForKey:@"CFBundleVersion"] UTF8String],
                                   
                                   [[[kextslist objectForKey:kext] objectForKey:@"CFBundleIdentifier"] UTF8String],
                                   [[[kextslist objectForKey:kext] objectForKey:@"OSBundlePath"] UTF8String]);
                        }
                    }
                }
                else
                    if (showApple) {
                        for (NSString* kext in kextslist.allKeys)
                        {
                            if ([[[kextslist objectForKey:kext] objectForKey:@"CFBundleIdentifier"] rangeOfString:@"com.apple" options:NSCaseInsensitiveSearch].location != NSNotFound)
                            {
                                printf("%s (%s) %s %s\n", kext.UTF8String,
                                       [[[kextslist objectForKey:kext] objectForKey:@"CFBundleVersion"] UTF8String],
                                       
                                       [[[kextslist objectForKey:kext] objectForKey:@"CFBundleIdentifier"] UTF8String],
                                       [[[kextslist objectForKey:kext] objectForKey:@"OSBundlePath"] UTF8String]);
                            }
                        }
                    }
                    else
                        if (showNonApple) {
                            for (NSString* kext in kextslist.allKeys)
                            {
                                if ([[[kextslist objectForKey:kext] objectForKey:@"CFBundleIdentifier"] rangeOfString:@"com.apple" options:NSCaseInsensitiveSearch].location == NSNotFound)
                                {
                                    printf("%s (%s) %s %s\n", kext.UTF8String,
                                           [[[kextslist objectForKey:kext] objectForKey:@"CFBundleVersion"] UTF8String],
                                           
                                           [[[kextslist objectForKey:kext] objectForKey:@"CFBundleIdentifier"] UTF8String],
                                           [[[kextslist objectForKey:kext] objectForKey:@"OSBundlePath"] UTF8String]);
                                }
                            }
                        }
                        else
                            if (showHelp) {
                                gotoHelp("kextstatx86");
                            }
                            else
                            {
                                for (NSString* kext in kextslist.allKeys)
                                {
                                    printf("%s (%s) %s %s\n", kext.UTF8String,
                                           [[[kextslist objectForKey:kext] objectForKey:@"CFBundleVersion"] UTF8String],
                                           
                                           [[[kextslist objectForKey:kext] objectForKey:@"CFBundleIdentifier"] UTF8String],
                                           [[[kextslist objectForKey:kext] objectForKey:@"OSBundlePath"] UTF8String]);
                                    
                                }
                            }
            
        }
        
    }
    return 0;
}
