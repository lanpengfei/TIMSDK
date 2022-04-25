//
//  TUIConversationCell.m
//  TXIMSDK_TUIKit_iOS
//
//  Created by annidyfeng on 2019/5/16.
//

#import "TUIConversationCell.h"
#import "TUIDefine.h"
#import "TUICommonModel.h"
#import "TUITool.h"
#import "TUIThemeManager.h"


@implementation TUIConversationCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = BACKGROUND_COLOR;
        self.backgroundColor = BACKGROUND_COLOR;
        
        UIView *view = [[UIView alloc] init];
        view.frame = CGRectMake(15,0,SCREEN_WIDTH - 30,78);
        view.layer.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0].CGColor;
        view.layer.cornerRadius = 4;
        view.layer.shadowColor = [UIColor colorWithRed:55/255.0 green:58/255.0 blue:64/255.0 alpha:0.04].CGColor;
        view.layer.shadowOffset = CGSizeMake(0,0.5);
        view.layer.shadowOpacity = 1;
        view.layer.shadowRadius = 5;
        [self.contentView addSubview:view];
        
        _headImageView = [[UIImageView alloc] init];
        
        [view addSubview:_headImageView];

        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont systemFontOfSize:12];
        _timeLabel.textColor = TUICoreDynamicColor(@"form_desc_color", @"#BBBBBB");
        _timeLabel.layer.masksToBounds = YES;
        [view addSubview:_timeLabel];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:18];
        _titleLabel.textColor = TUICoreDynamicColor(@"form_title_color", @"#333333");
        _titleLabel.layer.masksToBounds = YES;
        [view addSubview:_titleLabel];
        
        _jobLabel = [[UILabel alloc] init];
        _jobLabel.font = [UIFont systemFontOfSize:14];
        _jobLabel.textColor = TUICoreDynamicColor(@"form_title_color", @"#999999");
        _jobLabel.layer.masksToBounds = YES;
        [view addSubview:_jobLabel];

        _unReadView = [[TUIUnReadView alloc] init];
        [view addSubview:_unReadView];

        _subTitleLabel = [[UILabel alloc] init];
        _subTitleLabel.layer.masksToBounds = YES;
        _subTitleLabel.font = [UIFont systemFontOfSize:14];
        _subTitleLabel.textColor = TUICoreDynamicColor(@"form_subtitle_color", @"#1F1F1F");
        [view addSubview:_subTitleLabel];
        
        _notDisturbRedDot = [[UIView alloc] init];
        _notDisturbRedDot.backgroundColor = [UIColor redColor];
        _notDisturbRedDot.layer.cornerRadius = TConversationCell_Margin_Disturb_Dot / 2.0;
        _notDisturbRedDot.layer.masksToBounds = YES;
        [view addSubview:_notDisturbRedDot];
        
        _notDisturbView = [[UIImageView alloc] init];
        [view addSubview:_notDisturbView];

        [self setSeparatorInset:UIEdgeInsetsMake(0, TConversationCell_Margin, 0, 0)];

        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
        //[self setSelectionStyle:UITableViewCellSelectionStyleDefault];
        
        // selectedIcon
        _selectedIcon = [[UIImageView alloc] init];
        [view addSubview:_selectedIcon];
    }
    return self;
}
- (void)fillWithData:(TUIConversationCellData *)convData
{
    [super fillWithData:convData];
    self.convData = convData;

    self.timeLabel.text = [TUITool convertDateToStr:convData.time];
    self.subTitleLabel.attributedText = convData.subTitle;
    
    if (convData.isNotDisturb) {
        // 免打扰状态，如果没有未读消息，不展示小红点
        if (0 == convData.unreadCount) {
            self.notDisturbRedDot.hidden = YES;
        } else {
            self.notDisturbRedDot.hidden = NO;
        }
        self.notDisturbView.hidden = NO;
        self.unReadView.hidden = YES;
        UIImage *image = [UIImage d_imageWithImageLight:TUIConversationImagePath(@"message_not_disturb") dark:TUIConversationImagePath(@"message_not_disturb_dark")];
        [self.notDisturbView setImage:image];
    } else {
        self.notDisturbRedDot.hidden = YES;
        self.notDisturbView.hidden = YES;
        self.unReadView.hidden = NO;
        [self.unReadView setNum:convData.unreadCount];
    }

//    if (convData.isOnTop) {
//        self.contentView.backgroundColor = TUIConversationDynamicColor(@"conversation_cell_top_bg_color", @"#F4F4F4");
//    } else {
//        self.contentView.backgroundColor = TUIConversationDynamicColor(@"conversation_cell_bg_color", @"#FFFFFF");;
//    }
    
    if ([TUIConfig defaultConfig].avatarType == TAvatarTypeRounded) {
        self.headImageView.layer.masksToBounds = YES;
        self.headImageView.layer.cornerRadius = self.headImageView.frame.size.height / 2;
    } else if ([TUIConfig defaultConfig].avatarType == TAvatarTypeRadiusCorner) {
        self.headImageView.layer.masksToBounds = YES;
        self.headImageView.layer.cornerRadius = [TUIConfig defaultConfig].avatarCornerRadius;
    }

    @weakify(self)
    [[[RACObserve(convData, title) takeUntil:self.rac_prepareForReuseSignal]
      distinctUntilChanged] subscribeNext:^(NSString *x) {
        @strongify(self)
        self.titleLabel.text = x;
    }];
    
    
    // 修改默认头像
    if (convData.groupID.length > 0) {
        // 群组, 则将群组默认头像修改成上次使用的头像
        NSString *key = [NSString stringWithFormat:@"TUIConversationLastGroupMember_%@", convData.groupID];
        NSInteger member = [NSUserDefaults.standardUserDefaults integerForKey:key];
        UIImage *avatar = [TUIGroupAvatar getCacheAvatarForGroup:convData.groupID number:(UInt32)member];
        if (avatar) {
            convData.avatarImage = avatar;
        }
    }
    [[V2TIMManager sharedInstance]getUsersInfo:@[convData.userID] succ:^(NSArray<V2TIMUserFullInfo *> *infoList) {
        if (infoList.count > 0) {
            V2TIMUserFullInfo *info = [infoList firstObject];
            if ([info isKindOfClass:[V2TIMUserFullInfo class]]) {
                if ([CommonModel isValidDictWithIdType:info.customInfo]) {
                    NSDictionary *IMCustomInfoDic = info.customInfo;
                    if ([CommonModel isValidDictWithIdType:IMCustomInfoDic]) {
                        switch ([[PersonModel shareModel].usertype intValue]) {
                            case 1:
                                self.jobLabel.text = [self dataToStringWithData:IMCustomInfoDic[@"LinkJob"]];
                                break;
                            case 2:case 3:
                                self.jobLabel.text = [self dataToStringWithData:IMCustomInfoDic[@"HopeJob"]];
                                break;
                            default:
                                break;
                        }
                        [self setNeedsLayout];
                        [self layoutIfNeeded];
                    }
                }
            }
        }else {
            DSLog(@"未查到用户");
        }
    } fail:^(int code, NSString *desc) {
        
    }];
    [[RACObserve(convData,faceUrl) takeUntil:self.rac_prepareForReuseSignal] subscribeNext:^(NSString *x) {
        @strongify(self)
        if (self.convData.groupID.length > 0) { //群组
            // fix: 由于getCacheGroupAvatar需要请求网络，断网时，由于并没有设置headImageView，此时当前会话发消息，会话会上移，复用了第一条会话的头像，导致头像错乱
            self.headImageView.image = self.convData.avatarImage;
            [TUIGroupAvatar getCacheGroupAvatar:convData.groupID callback:^(UIImage *avatar) {
                @strongify(self)
                if (avatar != nil) { //已缓存群组头像
                    self.headImageView.image = avatar;
                } else { //未缓存群组头像
                    [self.headImageView sd_setImageWithURL:[NSURL URLWithString:x]
                                          placeholderImage:self.convData.avatarImage];
                    [TUIGroupAvatar fetchGroupAvatars:convData.groupID placeholder:convData.avatarImage callback:^(BOOL success, UIImage *image, NSString *groupID) {
                        @strongify(self)
                        if ([groupID isEqualToString:self.convData.groupID]) {
                            // 需要判断下，防止复用问题
                            [self.headImageView sd_setImageWithURL:[NSURL URLWithString:x] placeholderImage:image];
                        }
                    }];
                }
            }];
        } else {//个人头像
            [self.headImageView sd_setImageWithURL:[NSURL URLWithString:x]
                                  placeholderImage:self.convData.avatarImage];
        }
    }];
    
    NSString *imageName = (convData.showCheckBox && convData.selected) ? TUICoreImagePath(@"icon_select_selected") : TUICoreImagePath(@"icon_select_normal");
    self.selectedIcon.image = [UIImage imageNamed:imageName];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat height = [self.convData heightOfWidth:self.mm_w];
    self.mm_h = height;
    CGFloat imgHeight = 45;

    if (self.convData.showCheckBox) {
        _selectedIcon.mm_width(20).mm_height(20);
        _selectedIcon.mm_x = 10;
        _selectedIcon.mm_centerY = self.headImageView.mm_centerY;
        _selectedIcon.hidden = NO;
    } else {
        _selectedIcon.mm_width(0).mm_height(0);
        _selectedIcon.mm_x = 0;
        _selectedIcon.mm_y = 0;
        _selectedIcon.hidden = YES;
    }
    
    CGFloat margin = self.convData.showCheckBox ? _selectedIcon.mm_maxX : 0;
    self.headImageView.mm_width(imgHeight).mm_height(imgHeight).mm_left(TConversationCell_Margin + 3 + margin).mm_top(TConversationCell_Margin);
    if ([TUIConfig defaultConfig].avatarType == TAvatarTypeRounded) {
        self.headImageView.layer.masksToBounds = YES;
        self.headImageView.layer.cornerRadius = imgHeight / 2;
    } else if ([TUIConfig defaultConfig].avatarType == TAvatarTypeRadiusCorner) {
        self.headImageView.layer.masksToBounds = YES;
        self.headImageView.layer.cornerRadius = [TUIConfig defaultConfig].avatarCornerRadius;
    }

    self.timeLabel.mm_sizeToFit().mm_top(TConversationCell_Margin_Text).mm_right(TConversationCell_Margin + 4);
    [self.titleLabel sizeToFit];
    if (self.titleLabel.width > 100) {
        self.titleLabel.width = 100;
    }
    self.titleLabel.frame = CGRectMake(self.headImageView.mm_maxX+TConversationCell_Margin, TConversationCell_Margin_Text - 5, self.titleLabel.width, 30);
//    self.titleLabel.mm_sizeToFitThan(120, 30).mm_top(TConversationCell_Margin_Text - 5).mm_left(self.headImageView.mm_maxX+TConversationCell_Margin);
    [self.jobLabel sizeToFit];
    if (self.jobLabel.width > 100) {
        self.jobLabel.width = 100;
    }
    self.jobLabel.frame = CGRectMake(self.titleLabel.mm_maxX+TConversationCell_Margin_Disturb_Dot, TConversationCell_Margin_Text - 5, self.jobLabel.width, 30);
//    self.jobLabel.mm_sizeToFitThan(120, 30).mm_top(TConversationCell_Margin_Text - 5).mm_left(self.titleLabel.mm_maxX+TConversationCell_Margin_Disturb_Dot);
    self.subTitleLabel.mm_sizeToFit().mm_left(self.titleLabel.mm_x).mm_bottom(TConversationCell_Margin_Text).mm_flexToRight(2 * TConversationCell_Margin_Text);
    self.unReadView.mm_right(self.headImageView.mm_r - 5).mm_top(self.headImageView.mm_y - 5);
    self.notDisturbRedDot.mm_width(TConversationCell_Margin_Disturb_Dot).mm_height(TConversationCell_Margin_Disturb_Dot).mm_right(self.headImageView.mm_r - 3).mm_top(self.headImageView.mm_y - 3);
    self.notDisturbView.mm_width(TConversationCell_Margin_Disturb).mm_height(TConversationCell_Margin_Disturb).mm_right(16).mm_bottom(15);
}
- (NSString *)dataToStringWithData:(NSData *)data {
    if (data == nil) {
        return nil;
    }
    if ([data isKindOfClass:[NSString class]]) {
        NSString *dataString = (NSString *)data;
        return dataString;
    }
    if ([data isKindOfClass:[NSData class]]) {
        return [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}
@end

@interface IUConversationView : UIView
@property(nonatomic, strong) UIView *view;
@end

@implementation IUConversationView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        [self addSubview:self.view];
    }
    return self;
}
@end
