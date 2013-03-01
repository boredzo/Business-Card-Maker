//
//  PRHDocument.m
//  Business Card Maker
//
//  Created by Peter Hosey on 2012-09-12.
//  Copyright (c) 2012 Peter Hosey. All rights reserved.
//

#import "PRHDocument.h"

typedef NS_ENUM(NSUInteger, PRHCardMultiplier) {
	PRHCardCountOne = 1,
	PRHCardCountFillPage = 65535,
};

@interface PRHDocument ()

@property(copy) NSAttributedString *documentText;
@property(copy) NSDictionary *documentAttributes;

@property(unsafe_unretained /*because NSTextView hates kittens*/) IBOutlet NSTextView *editingTextView;

- (IBAction)exportPDF:(id)sender;

@property (strong) IBOutlet NSView *accessoryView;
@property (weak) IBOutlet NSMatrix *cardsPerPageMatrix;

@end

@implementation PRHDocument

- (id)init {
	self = [super init];
	if (self) {
		self.documentText = [[NSAttributedString alloc] init];
	}
	return self;
}

- (NSString *)windowNibName {
	return @"PRHDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
	[super windowControllerDidLoadNib:aController];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	NSDictionary *options = @{  };
	NSDictionary *freshAttributesHotOutOfTheParser;
	self.documentText = [[NSAttributedString alloc] initWithData:data options:options documentAttributes:&freshAttributesHotOutOfTheParser error:outError];
	self.documentAttributes = freshAttributesHotOutOfTheParser;
	return (self.documentText != nil);
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
	NSDictionary *attrs = self.documentAttributes ?: @{
		NSFileTypeDocumentAttribute: (__bridge id)kUTTypeRTF
	};
	return [self.documentText dataFromRange:(NSRange){ 0, self.documentText.length } documentAttributes:attrs error:outError];
}

- (NSView *) viewWithNumberOfCardsAcross:(NSUInteger)numAcross down:(NSUInteger)numDown {
	NSSize singleCardSize = self.editingTextView.frame.size;

	//Need to make the view exactly as big as the paper, positioning single-card text views in it appropriately for the business card sheets' margins
	NSRect totalFrame = { NSZeroPoint, singleCardSize };
	totalFrame.size.width *= numAcross;
	totalFrame.size.height *= numDown;
	NSView *containerView = [[NSView alloc] initWithFrame:totalFrame];

	NSRect singleCardFrame = { .size = singleCardSize };
	for (NSUInteger row = 0; row < numDown; ++row) {
		for (NSUInteger column = 0; column < numAcross; ++column) {
			singleCardFrame.origin = (NSPoint){ singleCardSize.width * column, singleCardSize.height * row };
			NSTextView *singleCardView = [[NSTextView alloc] initWithFrame:singleCardFrame];
			[singleCardView.textStorage setAttributedString:self.documentText];
			[containerView addSubview:singleCardView];
		}
	}

	return containerView;
}
- (IBAction)exportPDF:(id)sender {
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	savePanel.allowedFileTypes = @[ (__bridge NSString *)kUTTypePDF ];
	savePanel.accessoryView = self.accessoryView;
	[savePanel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result) {
		if (result == NSOKButton) {
			NSUInteger numAcross, numDown;
			if (self.cardsPerPageMatrix.selectedTag == PRHCardCountFillPage) {
				numAcross = 5;
				numDown = 2;
			} else {
				numAcross = numDown = 1;
			}
			NSView *view = [self viewWithNumberOfCardsAcross:numAcross down:numDown];
			NSPrintOperation *op = [NSPrintOperation PDFOperationWithView:view insideRect:[view bounds] toPath:savePanel.URL.path printInfo:[NSPrintInfo sharedPrintInfo]];
			op.canSpawnSeparateThread = YES;
			[op runOperationModalForWindow:[self windowForSheet] delegate:self didRunSelector:@selector(printOperationDidRun:success:contextInfo:) contextInfo:NULL];
		}
	}];
}

- (void)printOperationDidRun:(NSPrintOperation *)printOperation  success:(BOOL)success  contextInfo:(void *)contextInfo {
	
}

@end
