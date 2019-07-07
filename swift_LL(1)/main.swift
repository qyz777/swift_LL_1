//
//  main.swift
//  swift_LL(1)
//
//  Created by Q YiZhong on 2019/5/12.
//  Copyright © 2019 YiZhong Qi. All rights reserved.
//

import Foundation

let productions1 = ["E->TK", "K->+TK", "K->ε", "T->FM", "M->*FM", "M->ε", "F->i", "F->(E)"]
let sentence1 = "a+b#"
//let sentence2 = "i)+i#"
//    i+i*i
//    i)+i
let analyzer = Analyzer.init(with: productions1, with: sentence1)
analyzer.analyze()
