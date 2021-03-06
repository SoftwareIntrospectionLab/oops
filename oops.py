#!/usr/bin/env python
# encoding: utf-8
"""
oops.py

Created by Huascar A. Sanchez on 2013-02-08.
Copyright (c) 2013 Huascar A. Sanchez. All rights reserved.
"""

import sys, os
import subprocess

sys.path.insert(0, '..')

import json

from pycparser import c_parser, c_ast, parse_file # A Parser for the C language: https://bitbucket.org/eliben/pycparser

class Visitor(c_ast.NodeVisitor):
    def __init__(self):
        self.counter = 0
        
    def inc(self, val = 1):
        self.counter += val
    
    def count(self):
        return self.counter

class Oops(object):
    BIND_DIR = os.path.dirname(os.path.abspath(__file__))
    
    
    # Portable cpp path for Windows and Linux/Unix
    CPPPATH = '../utils/cpp.exe' if sys.platform == 'win32' else 'cpp'

    # While Loop Counter as recommended by pycparser.
    class WhileVisitor(Visitor):
        def __init__(self):
            Visitor.__init__(self)
    
        def visit_While(self, node):
            print (node.cond)
            Visitor.inc(self)      

    # DoWhile Loop Counter as recommended by pycparser.
    class DoWhileVisitor(Visitor):
        def __init__(self):
            Visitor.__init__(self)
    
        def visit_DoWhile(self, node):
            print (node.cond)
            Visitor.inc(self)
        
    # For Loop Counter as recommended by pycparser.
    class ForVisitor(Visitor):
        def __init__(self):
            Visitor.__init__(self)
    
        def visit_For(self, node):
            print (node.cond)
            Visitor.inc(self)
        
    
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
        
        
        totalwhiles  = 0
        totaldwhiles = 0
        totalfors    = 0 
    
        
        for file in files:
            try:
                
                ast     = parse_file(file, use_cpp=True,
                            cpp_path=self.CPPPATH, 
                            cpp_args=[r'-I./fake_libc_include',
                             r'-I'+self.BIND_DIR,
                             r'-I'+self.BIND_DIR+'/bind/lib/isc',
                             r'-I'+self.BIND_DIR+'/bind/lib/isc/unix/include',
                             r'-I'+self.BIND_DIR+'/bind/lib/isc/win32/include',
                             r'-I'+self.BIND_DIR+'/bind/lib/isc/include',
                             r'-I'+self.BIND_DIR+'/bind/lib/isc/powerpc/include',
                             r'-I'+self.BIND_DIR+'/bind/lib/isc/pthreads/include',
                             r'-I'+self.BIND_DIR+'/bind/lib/bind9/include',                             
                             r'-I'+self.BIND_DIR+'/bind/lib/dns/include',
                             r'-I'+self.BIND_DIR+'/bind/lib/irs/include',                             
                             r'-I'+self.BIND_DIR+'/bind/lib/isccc/include',                             
                             r'-I'+self.BIND_DIR+'/bind/lib/isccfg/include',                             
                             r'-I'+self.BIND_DIR+'/bind/lib/lwres/include', 
                             r'-I'+self.BIND_DIR+'/bind/lib/lwres/unix/include',                            
                             r'-I'+self.BIND_DIR+'/bind/tests/include' 
                            ])
            
                while_visitor.visit(ast)
                dowhi_visitor.visit(ast)
                forlo_visitor.visit(ast)
            
                ast.show()
                            
                totalwhiles  = totalwhiles  + while_visitor.count()
                totaldwhiles = totaldwhiles + dowhi_visitor.count()
                totalfors    = totalfors    + forlo_visitor.count()
                
                output.append(
                    dict(
                        filename    = os.path.basename(file), 
                        numwhile    = while_visitor.count(),
                        numdowhile  = dowhi_visitor.count(),
                        numfor      = forlo_visitor.count() 
                    )
                )        
                        
            except Exception as e:
                print "Unexpected parsing error ({0}): {1}".format(file,str(e)) 
            

        json_data = dict(files=[ r for r in output ], 
                         totals=dict(
                                totfiles   =len(files), 
                                totwhile   =totalwhiles, 
                                totdowhile =totaldwhiles, 
                                totfor     =totalfors
                        )
                    )
                       
         
        return json.dumps(json_data, indent=4, separators=(',', ': '))
    

if __name__ == '__main__':
    t = Oops()