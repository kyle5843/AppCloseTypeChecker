//
//  File.swift
//  AppCloseTypeChecker
//
//  Created by Kyle on 2020/8/7.
//  Copyright © 2020 Kyle.peng. All rights reserved.
//

import Foundation

/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*
*  Create protocols to just avoid the error warning.
*  You should create/import your own library.
*
* ------------------------------------------------------------*/
protocol Report { }
protocol CrashlyticsDelegate { }
struct CLSReport{ var isCrash:Bool }
