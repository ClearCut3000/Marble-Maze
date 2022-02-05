//
//  CollisionTypes.swift
//  Marble Maze
//
//  Created by Николай Никитин on 05.02.2022.
//

import Foundation

enum CollisionTypes: UInt32 {
  case player = 1
  case wall = 2
  case star = 4
  case vortex = 8
  case finish = 16
}
