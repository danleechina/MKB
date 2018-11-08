//
//  ScopedLock.hpp
//  Test
//
//  Created by Dan Lee on 2018/11/8.
//  Copyright © 2018 Dan Lee. All rights reserved.
//

#ifndef ScopedLock_hpp
#define ScopedLock_hpp

#import <Foundation/Foundation.h>

class CScopedLock {
    NSRecursiveLock *m_oLock;
    
public:
    CScopedLock(NSRecursiveLock *oLock) : m_oLock(oLock) { [m_oLock lock]; }
    
    ~CScopedLock() {
        [m_oLock unlock];
        m_oLock = nil;
    }
};

#endif /* ScopedLock_hpp */
