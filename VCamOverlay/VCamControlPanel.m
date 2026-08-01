#import "VCamControlPanel.h"

// Dark glassmorphism colors
#define PANEL_BG     [[UIColor blackColor] colorWithAlphaComponent:0.75]
#define SURFACE_CLR  [[UIColor whiteColor] colorWithAlphaComponent:0.08]
#define ACCENT_CLR   [UIColor colorWithRed:0.35 green:0.78 blue:1.0 alpha:1.0]
#define TEXT_CLR     [UIColor whiteColor]
#define TEXT2_CLR    [[UIColor whiteColor] colorWithAlphaComponent:0.6]
#define DANGER_CLR   [UIColor colorWithRed:1.0 green:0.35 blue:0.35 alpha:1.0]
#define SEPARATOR_CLR [[UIColor whiteColor] colorWithAlphaComponent:0.1]

static const CGFloat kPanelWidth  = 240;
static const CGFloat kPanelHeight = 380;
static const CGFloat kBtnSize     = 44;
static const CGFloat kPadding     = 12;

@implementation VCamControlPanel

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectMake(0, 0, kPanelWidth, kPanelHeight)];
    if (self) {
        [self setupPanel];
    }
    return self;
}

- (void)setupPanel {
    // Panel background — dark glass
    self.backgroundColor = PANEL_BG;
    self.layer.cornerRadius = 20;
    self.layer.borderWidth = 1;
    self.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.15].CGColor;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.6;
    self.layer.shadowRadius = 16;
    self.layer.shadowOffset = CGSizeMake(0, 4);
    self.clipsToBounds = NO;
    
    CGFloat y = kPadding;
    
    // ═══ Banner: "Vcam_Mch" ═══
    _bannerLabel = [[UILabel alloc] initWithFrame:CGRectMake(kPadding, y, kPanelWidth - 2*kPadding, 32)];
    _bannerLabel.text = @"Vcam_Mch";
    _bannerLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    _bannerLabel.textColor = ACCENT_CLR;
    _bannerLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_bannerLabel];
    y += 36;
    
    // Separator
    UIView *sep1 = [[UIView alloc] initWithFrame:CGRectMake(kPadding, y, kPanelWidth - 2*kPadding, 1)];
    sep1.backgroundColor = SEPARATOR_CLR;
    [self addSubview:sep1];
    y += 8;
    
    // ═══ Camera Control label ═══
    UILabel *sectionLabel = [[UILabel alloc] initWithFrame:CGRectMake(kPadding, y, kPanelWidth - 2*kPadding, 20)];
    sectionLabel.text = @"Camera Control";
    sectionLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    sectionLabel.textColor = TEXT2_CLR;
    sectionLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:sectionLabel];
    y += 24;
    
    // ═══ Row 1: Reset ═══
    UIButton *resetBtn = [self makeButton:@"arrow.counterclockwise"
                                  command:@"reset"
                                    label:@"Reset transform"
                                    color:DANGER_CLR];
    resetBtn.frame = CGRectMake((kPanelWidth - kBtnSize) / 2, y, kBtnSize, kBtnSize);
    [self addSubview:resetBtn];
    y += kBtnSize + 8;
    
    // ═══ Row 2: Up ═══
    UIButton *upBtn = [self makeButton:@"arrow.up" command:@"up" label:@"Move up" color:TEXT_CLR];
    upBtn.frame = CGRectMake((kPanelWidth - kBtnSize) / 2, y, kBtnSize, kBtnSize);
    [self addSubview:upBtn];
    y += kBtnSize + 4;
    
    // ═══ Row 3: Left | Rotate | Right ═══
    CGFloat leftX = (kPanelWidth - 3*kBtnSize - 2*8) / 2;
    UIButton *leftBtn = [self makeButton:@"arrow.left" command:@"left" label:@"Move left" color:TEXT_CLR];
    leftBtn.frame = CGRectMake(leftX, y, kBtnSize, kBtnSize);
    [self addSubview:leftBtn];
    
    UIButton *rotateBtn = [self makeButton:@"arrow.clockwise" command:@"rotate" label:@"Rotate image" color:ACCENT_CLR];
    rotateBtn.frame = CGRectMake(leftX + kBtnSize + 8, y, kBtnSize, kBtnSize);
    [self addSubview:rotateBtn];
    
    UIButton *rightBtn = [self makeButton:@"arrow.right" command:@"right" label:@"Move right" color:TEXT_CLR];
    rightBtn.frame = CGRectMake(leftX + 2*(kBtnSize + 8), y, kBtnSize, kBtnSize);
    [self addSubview:rightBtn];
    y += kBtnSize + 4;
    
    // ═══ Row 4: Down ═══
    UIButton *downBtn = [self makeButton:@"arrow.down" command:@"down" label:@"Move down" color:TEXT_CLR];
    downBtn.frame = CGRectMake((kPanelWidth - kBtnSize) / 2, y, kBtnSize, kBtnSize);
    [self addSubview:downBtn];
    y += kBtnSize + 8;
    
    // Separator
    UIView *sep2 = [[UIView alloc] initWithFrame:CGRectMake(kPadding, y, kPanelWidth - 2*kPadding, 1)];
    sep2.backgroundColor = SEPARATOR_CLR;
    [self addSubview:sep2];
    y += 8;
    
    // ═══ Row 5: Zoom Out | Zoom Label | Zoom In ═══
    CGFloat zoomLeftX = (kPanelWidth - 3*kBtnSize - 2*8) / 2;
    
    UIButton *zoomOutBtn = [self makeButton:@"minus.magnifyingglass" command:@"zoomout" label:@"Zoom out" color:TEXT_CLR];
    zoomOutBtn.frame = CGRectMake(zoomLeftX, y, kBtnSize, kBtnSize);
    [self addSubview:zoomOutBtn];
    
    _zoomLabel = [[UILabel alloc] initWithFrame:CGRectMake(zoomLeftX + kBtnSize + 8, y, kBtnSize, kBtnSize)];
    _zoomLabel.text = @"1.00x";
    _zoomLabel.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightSemibold];
    _zoomLabel.textColor = ACCENT_CLR;
    _zoomLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_zoomLabel];
    
    UIButton *zoomInBtn = [self makeButton:@"plus.magnifyingglass" command:@"zoomin" label:@"Zoom in" color:TEXT_CLR];
    zoomInBtn.frame = CGRectMake(zoomLeftX + 2*(kBtnSize + 8), y, kBtnSize, kBtnSize);
    [self addSubview:zoomInBtn];
    y += kBtnSize + 8;
    
    // ═══ Row 6: Flip ═══
    UIButton *flipBtn = [self makeButton:@"arrow.left.and.right" command:@"flip" label:@"Flip image" color:TEXT_CLR];
    flipBtn.frame = CGRectMake((kPanelWidth - kBtnSize) / 2, y, kBtnSize, kBtnSize);
    [self addSubview:flipBtn];
    y += kBtnSize + kPadding;
    
    // ═══ Close button ═══
    UIButton *closeBtn = [self makeButton:@"chevron.right" command:@"close" label:@"Close controls" color:TEXT2_CLR];
    closeBtn.frame = CGRectMake(kPanelWidth - kBtnSize - 8, 8, 32, 32);
    [self addSubview:closeBtn];
}

- (UIButton *)makeButton:(NSString *)sfSymbol
                  command:(NSString *)command
                    label:(NSString *)accessLabel
                    color:(UIColor *)color {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.backgroundColor = SURFACE_CLR;
    btn.layer.cornerRadius = kBtnSize / 2;
    btn.tintColor = color;
    
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightMedium];
    UIImage *img = [[UIImage systemImageNamed:sfSymbol] imageWithConfiguration:cfg];
    [btn setImage:img forState:UIControlStateNormal];
    btn.accessibilityLabel = accessLabel;
    
    btn.tag = [self tagForCommand:command];
    [btn addTarget:self action:@selector(commandTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    return btn;
}

- (NSInteger)tagForCommand:(NSString *)cmd {
    static NSDictionary *cmdMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cmdMap = @{
            @"reset": @100, @"up": @101, @"left": @102, @"rotate": @103,
            @"right": @104, @"down": @105, @"zoomout": @106, @"zoomin": @107,
            @"flip": @108, @"close": @109
        };
    });
    return [cmdMap[cmd] integerValue];
}

- (NSString *)commandForTag:(NSInteger)tag {
    static NSDictionary *tagMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tagMap = @{
            @100: @"reset", @101: @"up", @102: @"left", @103: @"rotate",
            @104: @"right", @105: @"down", @106: @"zoomout", @107: @"zoomin",
            @108: @"flip", @109: @"close"
        };
    });
    return tagMap[@(tag)];
}

- (void)commandTapped:(UIButton *)sender {
    NSString *cmd = [self commandForTag:sender.tag];
    if (!cmd) return;
    
    if ([cmd isEqualToString:@"close"]) {
        // Animate close
        [UIView animateWithDuration:0.2 animations:^{
            self.alpha = 0;
            self.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:^(BOOL finished) {
            self.hidden = YES;
        }];
        return;
    }
    
    if (_commandHandler) {
        _commandHandler(cmd);
    }
    
    // Button press feedback
    [UIView animateWithDuration:0.1 animations:^{
        sender.transform = CGAffineTransformMakeScale(0.85, 0.85);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            sender.transform = CGAffineTransformIdentity;
        }];
    }];
}

- (void)updatePanelFrame {
    // Position relative to screen
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    UIEdgeInsets safeArea = UIEdgeInsetsZero;
    if (@available(iOS 15.0, *)) {
        UIWindow *window = self.window;
        if (window) {
            safeArea = window.safeAreaInsets;
        }
    }
    
    CGFloat x = (screenBounds.size.width - kPanelWidth) / 2;
    CGFloat y = safeArea.top + 60;
    self.frame = CGRectMake(x, y, kPanelWidth, kPanelHeight);
}

- (void)updateZoomValue:(CGFloat)zoom {
    _zoomLabel.text = [NSString stringWithFormat:@"%.2fx", zoom];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    // Pass through touches that don't hit any interactive element
    if (hit == self) return nil;
    return hit;
}

@end
