//
//  Analyzer.swift
//  swift_LL(1)
//
//  Created by Q YiZhong on 2019/5/12.
//  Copyright © 2019 YiZhong Qi. All rights reserved.
//

import Foundation

class Analyzer {
    
//    非终结符
    private var vnSet: Set<Character> = []
//    终结符
    private var vtSet: Set<Character> = []
    
//    first集
    private var firstInfo: [Character: Set<Character>] = [:]
    
    private var firstStrInfo: [String: Set<Character>] = [:]
    
//    follow集
    private var followInfo: [Character: Set<Character>] = [:]
    
//    非终结符:(产生式 VN->XXX)
    private var productionInfo: [Character: [String]] = [:]
    
    private var table: [[String]] = []
    
    private var analyzeStack: [Character] = []
    
    private var beginSymbol: Character = "E"
    
    private var inputStr = "i+i*i#"
    
    private var option = ""
    
    init(with list: [String]) {
        for str in list {
            var row: [String] = str.components(separatedBy: "->")
            let vn = Character(row.removeFirst())
            vnSet.insert(vn)
            var productionArray = productionInfo[vn] == nil ? Array<String>() : productionInfo[vn]!
            productionArray.append(row.first!)
            productionInfo[vn] = productionArray
        }
        for str in list {
            var row: [String] = str.components(separatedBy: "->")
            for c in Array(row[1]) {
                if !vnSet.contains(c) {
                    vtSet.insert(c)
                }
            }
        }
        for symbol in vnSet {
            setupFirstInfo(with: symbol)
        }
        setupFollowInfo(with: beginSymbol)
        for symbol in vnSet {
            setupFollowInfo(with: symbol)
        }
        createTable()
    }
    
    public func analyze() {
        showInfo()
        print("——————————LL1分析过程——————————")
        analyzeStack.append("$")
        analyzeStack.append(beginSymbol)
        var i = 0
        showRow(with: i)
        var vn = analyzeStack.last!
        while vn != "$" {
            let vt = Character(inputStr.subString(from: i, length: 1))
            if vn == vt {
                option = "匹配 \(analyzeStack.popLast()!)"
                i += 1
            } else if vtSet.contains(vn) {
                return
            } else if findElementFromTable(vn: vn, vt: vt) == "" {
                return
            } else if findElementFromTable(vn: vn, vt: vt) == "ε" {
                analyzeStack.removeLast()
                option = "\(vn)->ε"
            } else {
                let str = findElementFromTable(vn: vn, vt: vt)
                if !str.isEmpty {
                    option = "\(vn)->\(str)"
                    analyzeStack.removeLast()
                    for i in (0..<str.count).reversed() {
                        analyzeStack.append(Character(str.subString(from: i, length: 1)))
                    }
                }
            }
            vn = analyzeStack.last!
            showRow(with: i)
        }
    }
    
    /// 设置first集，这是个DFS
    ///
    /// 1.如果X为终结符,First(X)=X
    /// 2.如果X->ε是产生式，把ε加入First(X)
    /// 3.如果X是非终结符，如X->YZW。从左往右扫描产生式右部，把First(Y)加入First(X)。
    /// 如果First(Y)不包含ε，表示Y不可为空，便不再往后处理；如果First(Y)包含ε，表示Y可为空，则处理Z，依次类推
    ///
    /// - Parameter symbol: 输入的符号
    private func setupFirstInfo(with symbol: Character) {
        guard firstInfo[symbol] == nil else {
            return
        }
        var set: Set<Character> = []
//        如果X为终结符，First(X)=X
        if vtSet.contains(symbol) {
            set.insert(symbol)
            firstInfo[symbol] = set
        } else {
            for s in productionInfo[symbol]! {
                if symbol == "ε" {
//                    如果X->ε是产生式，把ε加入First(X)
                    set.insert(symbol)
                } else {
                    for c in s {
                        if firstInfo[c] == nil {
                            setupFirstInfo(with: c)
                        }
                        set.formUnion(firstInfo[c] ?? [])
//                        不包含ε，不再往后处理
                        if !set.contains("ε") {
                            break
                        }
                    }
                }
            }
            firstInfo[symbol] = set
        }
    }
    
    private func setupFirstStrInfo(with symbol: String) {
        guard firstStrInfo[symbol] == nil else {
            return
        }
        var set: Set<Character> = []
        var i = 0
        while i < symbol.count {
            let cur = Character(symbol.subString(from: i, length: 1))
            if firstInfo[cur] == nil {
                setupFirstInfo(with: cur)
            }
            let rightSet = firstInfo[cur]!
            set.formUnion(rightSet)
            if rightSet.contains("ε") {
                i += 1
            } else {
                break
            }
            if i == symbol.count {
                set.insert("ε")
            }
        }
        firstStrInfo[symbol] = set
    }
    
    /// 设置follow集
    ///
    /// 以A->αBβ形式说明
    /// 1.$属于FOLLOW(S)，S是开始符
    /// 2.查找输入的所有产生式，确定X后一个终结符
    /// 3.如果存在A->αBβ，（α、β是任意文法符号串，A、B为非终结符），把first(β)的非空符号加入follow(B)
    /// 4.如果存在A->αB或A->αBβ 且first(β)包含空，把follow(A)加入follow(B)
    ///
    /// - Parameter symbol: 输入符号
    private func setupFollowInfo(with symbol: Character) {
        let productionArray = productionInfo[symbol] ?? []
//        相当于follow(A)
        var symbolFollowSet = followInfo[symbol] == nil ? Set<Character>() : followInfo[symbol]!
        if symbol == beginSymbol {
//            开始符号
            symbolFollowSet.insert("$")
        }
        for vn in vnSet {
            for s in productionInfo[vn]! {
                for i in 0..<s.count {
                    let p = Character(s.subString(from: i, length: 1))
//                    查找所有产生式，确定X后一个的终结符
                    if symbol == p &&
                        i + 1 < s.count &&
                        vtSet.contains(Character(s.subString(from: i + 1, length: 1))) {
                        symbolFollowSet.insert(Character(s.subString(from: i + 1, length: 1)))
                    }
                }
            }
        }
        followInfo[symbol] = symbolFollowSet
        for pro in productionArray {
            for i in (0..<pro.count).reversed() {
                let cur = Character(pro.subString(from: i, length: 1))
                if followInfo[cur] == nil {
//                    这里有个DFS
                    setupFollowInfo(with: cur)
                }
//                相当于follow(B)
                var curFollowSet = followInfo[cur]!
                if vnSet.contains(cur) {
                    if i + 1 >= pro.count {
//                        最后一个，这个时候没有右边的非终结符，把follow(A)加入到follow(B)中
                        curFollowSet.formUnion(symbolFollowSet)
                    } else {
                        let rightSymbol = pro.subString(from: i + 1, length: pro.count - i - 1)
                        var rightSymbolFirstSet: Set<Character> = []
                        if rightSymbol.count == 1 {
                            if firstInfo[Character(rightSymbol)] == nil {
                                setupFirstInfo(with: Character(rightSymbol))
                            }
                            rightSymbolFirstSet = firstInfo[Character(rightSymbol)]!
                        } else {
                            if firstStrInfo[rightSymbol] == nil {
                                setupFirstStrInfo(with: rightSymbol)
                            }
                            rightSymbolFirstSet = firstStrInfo[rightSymbol]!
                        }
//                        A->αBβ 把first(β)的非空符号加入follow(B)
                        for s in rightSymbolFirstSet {
                            if s != "ε" {
                                curFollowSet.insert(s)
                            }
                        }
//                        β包含空，把follow(symbol) 加入 follor(cur)中
                        if rightSymbolFirstSet.contains("ε") {
                            curFollowSet.formUnion(symbolFollowSet)
                        }
                    }
                    followInfo[cur] = curFollowSet
                }
            }
        }
    }
    
    private func createTable() {
        let vnArray = Array(vnSet)
        let vtArray = Array(vtSet)
        table = Array.init(repeating: Array.init(repeating: "error", count: vtArray.count + 1), count: vnArray.count + 1)
        table[0][0] = "vn/vt"
        for i in 1...vtArray.count {
            table[0][i] = String(vtArray[i - 1])
        }
        for i in 1...vnArray.count {
            table[i][0] = String(vnArray[i - 1])
        }
        for vn in vnSet {
            for s in productionInfo[vn]! {
                if firstStrInfo[s] == nil {
                    setupFirstStrInfo(with: s)
                }
                let firstSet = firstStrInfo[s]!
                for e in firstSet {
                    insertElementIntoTable(vn: vn, vt: e, production: s)
                }
                if firstSet.contains("ε") {
                    let followSet = followInfo[vn]!
                    if followSet.contains("$") {
                        insertElementIntoTable(vn: vn, vt: "$", production: s)
                    }
                    for e in followSet {
                        insertElementIntoTable(vn: vn, vt: e, production: s)
                    }
                }
            }
        }
    }
    
    private func insertElementIntoTable(vn: Character, vt: Character, production: String) {
        for i in 0...vnSet.count {
            if table[i][0] == String(vn) {
                for j in 0...vtSet.count {
                    if table[0][j] == String(vt) {
                        table[i][j] = production
                        return
                    }
                }
            }
        }
    }
    
    private func findElementFromTable(vn: Character, vt: Character) -> String {
        for i in 0...vnSet.count {
            if table[i][0] == String(vn) {
                for j in 0...vtSet.count {
                    if table[0][j] == String(vt) {
                        return table[i][j]
                    }
                }
            }
        }
        return ""
    }
    
    private func showInfo() {
        showFirstSet()
        showFollowSet()
        showTable()
    }
    
    private func showFirstSet() {
        print("——————————First集——————————")
        for vn in vnSet {
            let firstSet = firstInfo[vn]!
            var rightStr = ""
            for str in firstSet {
                rightStr += String(str)
            }
            print("FIRST(\(vn))    =    \(rightStr)")
        }
        for (k, v) in firstStrInfo {
            var str = ""
            for e in v {
                str += String(e)
            }
            print("FIRST(\(k))    =    \(str)")
        }
    }
    
    private func showFollowSet() {
        print("——————————Follow集——————————")
        for vn in vnSet {
            let followSet = followInfo[vn]!
            var rightStr = ""
            for str in followSet {
                rightStr += String(str)
            }
            print("FOLLOW(\(vn))    =    \(rightStr)")
        }
    }
    
    private func showTable() {
        print("——————————预测分析表M——————————")
        for i in 0..<table.count {
            var row = ""
            for s in table[i] {
                row += s + String.init(repeating: " ", count: 10 - s.count)
            }
            print(row)
        }
    }
    
    private func showRow(with index: Int) {
        var stackStr = ""
        for c in analyzeStack {
            stackStr.append(c)
        }
        stackStr = stackStr + String.init(repeating: " ", count: 30 - stackStr.count)
        var inputChar = inputStr.subString(from: index, length: 1)
        inputChar = inputChar + String.init(repeating: " ", count: 20 - inputChar.count)
        print(stackStr + inputChar + option)
    }
    
}

extension String {
    
    func subString(from: Int, length: Int) -> String {
        return String(self[self.index(self.startIndex, offsetBy: from)..<self.index(self.startIndex, offsetBy: from + length)])
    }
    
}
