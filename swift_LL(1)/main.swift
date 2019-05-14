//
//  main.swift
//  swift_LL(1)
//
//  Created by Q YiZhong on 2019/5/12.
//  Copyright © 2019 YiZhong Qi. All rights reserved.
//

import Foundation

/**
 大写是非终结符，小写是终结符
 */

let productions = ["E->TK", "K->+TK", "K->ε", "T->FM", "M->*FM", "M->ε", "F->i", "F->(E)"]

let analyzer = Analyzer.init(with: productions)
analyzer.analyze()
