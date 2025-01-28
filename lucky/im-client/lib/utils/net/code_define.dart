/// 错误代码枚举
class CodeDefine {
  /////////////----------------客户端自己定义的 开始分割线---------------------/////////////////////////////////////
  static const int success = 0;
  // im找不到用户
  static const int codeUnfindUser = -201;
  // 扣钱失败
  static const int codeMoneyFail = -501;
  // 还没扣费过
  static const int codeNoPaid = -502;
  // 客户端版本错误
  static const int codeErrorVersion = -503;
  // 付费类型不对
  static const int codePayTypeErr = -8001;
  // 未登录的code
  static const int codeNotLogin = -10000;
  // 被踢线
  static const int codeOtherKick = -10001;
  // 无效用户
  static const int codeUnknowUser = -10010;
  static const int codeTimeout = -50001;
  static const int codeParseFail = -50002;
  static const int codeRunError = -50003;
  static const int codeNotNet = -50004;
  static const int codeBodyNull = -50005;
  static const int codeBodyNil = -50006;
  static const int codeBodyNullString = -50007;
  static const int codeBodyTypeErr = -50008;
  static const int codeBodyDecodeErr = -50009;
  static const int codeBodyNotCode = -50010;
  static const int codeBodyCodeNotInt = -50011;
  static const int codeServiceCrash = -50500;
  // 包超时的code
  // 解包失败的code
  // 出错的code
  // 没有网络的code
  // body是null
  // body是字符串nil
  // body是空字符串
  // body类型不对
  // body解开json出错
  // body没有code
  // body的code不是数字
  // 服务端崩溃的code

  ////////////////////////////////////////////////////////////
  static const int codeHttpUnknowErr = -55000;
  static const int codeHttpConnectTimeout = -55600;
  static const int codeHttpSendTimeout = -55601;
  static const int codeHttpReceiveTimeout = -55602;
  static const int codeHttpResponse = -55603;
  static const int codeHttpCancel = -55604;
  static const int codeHttpDefault = -55605;
  static const int codeHttpNetError = -55606;
  // http自定义错误 -55000到-56000
  // http连接超时
  // http请求超时
  // http响应超时
  // http出现异常,一般不会进这个,应该是变成-55500了
  // http请求取消
  // http未知错误
  // http网络断了错误
  static int getHttpErrStatus(int statusCode) {
    assert(statusCode >= 0 && statusCode < 1000);
    return codeHttpUnknowErr - statusCode;
  }

  /////////////----------------客户端自己定义的 结束分割线---------------------/////////////////////////////////////

  // 一键登陆过于频繁
  static const int codeQuickLoginMore = 103911;

  /////////////----------------与服务端定义对应 开始分割线---------------------/////////////////////////////////////

  // 包超速
  // 封号
  // 创建信号
  // 账号密码为空
  // 账号密码错误
  // wx账号已存在
  //ios账号已存在
  //登陆失败
  //账号不存在
  //该账户没有绑定手机
  //注册失败
  //请使用普通登陆
  //绑定账号已存在，无法绑定
  //验证码错误
  //绑定存储失败
  //动态已被删除
  //发布内容因涉嫌违规已被平台屏蔽
  static const int codeTimeQuick = 50001;
  static const int codeFengHao = 10004;
  static const int codeCreateUser = 10005;
  static const int USER_LOGIN_ACCOUNT_PASSWORD_EMPTY = 30100;
  static const int USER_LOGIN_ACCOUNT_PASSWORD_ERROR = 30101;
  static const int USER_LOGIN_WX_EXIST = 30102;
  static const int USER_LOGIN_IOS_EXIST = 30103;
  static const int USER_LOGIN_FAIL = 30104;
  static const int USER_LOGIN_ACCOUNT_NOT_EXIST = 30105;
  static const int USER_MOBILE_ERROR = 30106;
  static const int USER_REG_FAIL = 30107;
  static const int TO_NOMARL_LOGIN = 30108;
  static const int USER_LOGIN_ACCOUNT_EXIST = 30109;
  static const int USER_LOGIN_ACCOUNT_VCODE_ERR = 30110;
  static const int BIND_WX_AND_IOS_FAIL = 30111;
  static const int POST_ALEADY_DELETE = 20505;
  static const int POST_ILLEGALITY = 20506;

  /////////////----------------与服务端定义对应 结束分割线---------------------/////////////////////////////////////
}

enum ErrorCode {
  SUCCESS(0),
  CODE_NOTFOUND_USER(-201), // im找不到用户
  CODE_MONEY_FAIL(-501), // 扣钱失败
  CODE_NO_PAID(-502), // 还没扣费过
  CODE_ERROR_VERSION(-503), // 客户端版本错误
  CODE_PAY_TYPE_ERR(-8001), // 付费类型不对
  CODE_NOT_LOGIN(-10000), // 未登录的code
  CODE_OTHER_KICK(-10001), // 被踢线
  CODE_UNKNOWN_USER(-10010), // 无效用户
  CODE_TIME_OUT(-50001), // 包超时的code
  CODE_PARSE_FAIL(-50002), // 解包失败的code
  CODE_RUN_ERR(-50003), // 出错的code
  CODE_NO_NET(-50004), // 没有网络的code
  CODE_BODY_NULL(-50005), // body是null
  CODE_BODY_NIL(-50006), // body是字符串nil
  CODE_BODY_NULL_STRING(-50007), // body是空字符串
  CODE_BODY_TYPE_ERR(-50008), // body类型不对
  CODE_BODY_DECODE_ERR(-50009), // body解开json出错
  CODE_BODY_NOT_CODE(-50010), // body没有code
  CODE_BODY_CODE_NOT_INT(-50011), // body的code不是数字
  CODE_SERVICE_CRASH(-50500), // 服务端崩溃的code
  CODE_HTTP_UNKNOWN_ERR(-55000), // http自定义错误 -55000到-56000
  CODE_HTTP_CONNECT_TIMEOUT(-55600), // http连接超时
  CODE_HTTP_RECEIVE_TIMEOUT(-55601), // http请求超时
  CODE_HTTP_SEND_TIMEOUT(-55602), // http响应超时
  CODE_HTTP_RESPONSE(-55603), // http出现异常,一般不会进这个,应该是变成-55500了
  CODE_HTTP_CANCEL(-55604), // http请求取消
  CODE_HTTP_DEFAULT(-55605), // http未知错误
  CODE_HTTP_NET_ERR(-55606), // http网络断了错误
  CODE_QUICK_LOGIN_MORE(103911), // 一键登陆过于频繁
  CODE_TIME_QUICK(50001), // 包超速
  CODE_FENG_HAO(10004), // 封号
  CODE_CREATE_USER(10005), // 创建信号
  USER_LOGIN_ACCOUNT_PASSWORD_EMPTY(30100), // 账号密码为空
  USER_LOGIN_ACCOUNT_PASSWORD_ERR(30101), // 账号密码错误
  USER_LOGIN_WX_EXIST(30102), // wx账号已存在
  USER_LOGIN_IOS_EXIST(30103), //ios账号已存在
  USER_LOGIN_FAIL(30104), // 登陆失败
  USER_LOGIN_ACCOUNT_NOT_EXIST(30105), // 账号不存在
  USER_MOBILE_ERR(30106), // 该账户没有绑定手机
  USER_REG_FAIL(30107), // 注册失败
  TO_NORMAL_LOGIN(30108), // 请使用普通登陆
  USER_LOGIN_ACCOUNT_EXIST(30109), // 绑定账号已存在，无法绑定
  USER_LOGIN_ACCOUNT_VCODE_ERR(30110), // 验证码错误
  BIND_WX_AND_IOS_FAIL(30111), // 绑定存储失败
  POST_ALREADY_DELETE(20505), // 动态已被删除
  POST_ILLEGALITY(20506); // 发布内容因涉嫌违规已被平台屏蔽

  const ErrorCode(this.value);

  final int value;
}
