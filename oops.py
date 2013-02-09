#!/usr/bin/env python
# encoding: utf-8
"""
oops.py

Created by Huascar A. Sanchez on 2013-02-08.
Copyright (c) 2013 Huascar A. Sanchez. All rights reserved.
"""

import sys, os
import subprocess

from pycparser import c_parser, c_ast, parse_file # A Parser for the C language: https://bitbucket.org/eliben/pycparser

class oops(object):
    BIND_DIR = os.path.dirname(os.path.abspath(__file__))
    
    # Portable cpp path for Windows and Linux/Unix
    CPPPATH = '../utils/cpp.exe' if sys.platform == 'win32' else 'cpp'
    
    # While Loop Counter as recommended by pycparser.
    class WhileVisitor(c_ast.NodeVisitor):
        def __init__(self):
            self.counter    = 0
    
        def visit_While(self, node):
            print (node.cond)
            self.counter += 1
        
        def report(self):
                return "no_while = " + str(self.counter)        

    # DoWhile Loop Counter as recommended by pycparser.
    class DoWhileVisitor(c_ast.NodeVisitor):
        def __init__(self):
            self.counter    = 0
    
        def visit_DoWhile(self, node):
            print (node.cond)
            self.counter += 1
        
        def report(self):
            return "no_do_while = " + str(self.counter) 
        
    # For Loop Counter as recommended by pycparser.
    class ForVisitor(c_ast.NodeVisitor):
        def __init__(self):
            self.counter    = 0
    
        def visit_For(self, node):
            print (node.cond)
            self.counter += 1
        
        def report(self):
            return "no_for = " + str(self.counter)   

        
    def __init__(self):
        files   = self.walk(self.BIND_DIR)
        output  = self.peek(files)
        print(output)
        
    def walk(self, path):
        results = []
        for root, dirs, files in os.walk(path):
            for file in files:
                if(file.endswith(".c")):
                    results.append(os.path.join(root,file))            
        
        return results                
    
    def peek(self, files):
        output = []
        while_visitor = self.WhileVisitor()
        dowhi_visitor = self.DoWhileVisitor()
        forlo_visitor = self.ForVisitor()   

        
        for file in files:
            ast = parse_file(file, use_cpp=True,
                        cpp_path=self.CPPPATH)
            
            while_visitor.visit(ast)
            dowhi_visitor.visit(ast)
            forlo_visitor.visit(ast)
            
            ast.show
            
            output.append(while_visitor.report())
            output.append(dowhi_visitor.report())
            output.append(forlo_visitor.report())
        
        return ','.join(output)
        


if __name__ == '__main__':
    t = oops()