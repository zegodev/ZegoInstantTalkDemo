package com.zego.instanttalk.interfaces;


import com.zego.biz.BizUser;

import java.util.List;

/**
 * Copyright © 2016 Zego. All rights reserved.
 * des:
 */

public interface UserListView {
    void onUserListUpdate(List<BizUser> listUser);
}
