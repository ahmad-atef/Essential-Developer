//
//  LoginModule.swift
//  essentialDeveloper
//
//  Created by Ahmed Atef Ali Ahmed on 23.04.21.
//

import Foundation

struct UserProfile {}

protocol LoginHandler {
    func login(username: String, password: String, completion: ((_ userProfile: UserProfile) -> ()))
}

class LoginModule {

    private let loginHandler: LoginHandler

    init(loginHandler: LoginHandler) {
        self.loginHandler = loginHandler
    }

    func login(username: String, password: String) {
        loginHandler.login(username: username, password: password) { userProfile in

        }
    }
}
