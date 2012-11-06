/* WizDebugLog - swap NSlog with wizLog
 *
 * @author Ally Ogilvie 
 * @copyright WizCorp Inc. [ Incorporated Wizards ] 2011
 * @file WizDebugLog.h
 *
 *
 * Under project settings add the following to the "DEBUGGER" 
 * line in the LLVM pre-compile options category 
 *
 *
 */

#ifdef DEBUGGER
#define WizLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define WizLog( s, ... ) 
#endif