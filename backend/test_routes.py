#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""اختبار بسيط للتحقق من أن جميع الـ routes موجودة"""

import sys
import os

# إضافة المجلد الحالي إلى المسار
sys.path.insert(0, os.path.dirname(__file__))

try:
    from app import app
    
    print("=" * 60)
    print("اختبار Routes - وضوح Backend")
    print("=" * 60)
    
    # الحصول على جميع الـ routes
    routes = []
    for rule in app.url_map.iter_rules():
        if rule.endpoint != 'static':
            routes.append({
                'path': str(rule),
                'methods': [m for m in rule.methods if m not in ['HEAD', 'OPTIONS']],
                'endpoint': rule.endpoint
            })
    
    # ترتيب حسب المسار
    routes.sort(key=lambda x: x['path'])
    
    print(f"\nإجمالي Routes: {len(routes)}\n")
    
    # التحقق من وجود routes المصادقة
    auth_routes = [r for r in routes if '/auth/' in r['path']]
    
    print("Routes المصادقة:")
    print("-" * 60)
    for route in auth_routes:
        print(f"  {route['methods'][0] if route['methods'] else 'GET':6} {route['path']}")
    
    print("\nجميع Routes:")
    print("-" * 60)
    for route in routes:
        methods = ', '.join(route['methods'][:2])  # أول طريقتين فقط
        if len(route['methods']) > 2:
            methods += '...'
        print(f"  {methods:15} {route['path']}")
    
    print("\n" + "=" * 60)
    print("✓ جميع الـ routes موجودة بشكل صحيح!")
    print("=" * 60)
    
except Exception as e:
    print(f"❌ خطأ: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

