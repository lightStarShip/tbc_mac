//
//  ImportAccount.swift
//  theBigDipper
//
//  Created by wesley on 2022/9/6.
//

import SwiftUI

struct ImportAccountView: View {
        var body: some View {
                ZStack {
                        Color.blue.frame(width: 200, height: 200)
                        VStack{
                                
                                Text("Popup!")
                                
                                Text("Popup!")
                                Button("test") {
                                        print("-------->")
                                }
                                Text("Popup!")
                        }
                }.frame(width: 200, height: 200, alignment: .leading)
        }
}

struct ImportAccount_Previews: PreviewProvider {
        static var previews: some View {
                ImportAccountView()
        }
}
