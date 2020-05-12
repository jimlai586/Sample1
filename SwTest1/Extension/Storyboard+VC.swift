//
//  StoryboardExt.swift
//  SwTest1
//
//  Created by JimLai on 2020/4/11.
//  Copyright © 2020 stargate. All rights reserved.
//

import UIKit

extension UIViewController {
    static var name: String {
        return String(describing: self)
    }
}

infix operator !?

public func !? <T>(wrapped: T?, nilDefault: @autoclosure () -> (value: T, text: String)) -> T {
    assert(wrapped != nil, nilDefault().text)
    return wrapped ?? nilDefault().value
}

func sb<T>() -> T where T: UIViewController {
    return UIStoryboard(name: T.name, bundle: Bundle.main).instantiateInitialViewController() as? T !? (T(), "\(T.name) not instantiated")
}

