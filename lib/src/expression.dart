import 'token.dart';
import 'constants.dart';

/// 抽象的访问者模式，包含访问表达式的抽象语法树的接口
///
///语句和表达式的区别在于：1，语句以";"结尾，而表达式没有";""
///
/// 2，访问语句返回void，访问表达式返回dynamic
///
/// 3，访问语句称作execute，访问表达式称作evaluate
///
/// 4，语句包含表达式，而表达式不包含语句
abstract class ExprVisitor {
  /// 字面量
  dynamic visitLiteralExpr(LiteralExpr expr);

  /// 单目表达式
  dynamic visitUnaryExpr(UnaryExpr expr);

  /// 双目表达式
  dynamic visitBinaryExpr(BinaryExpr expr);

  /// 变量
  dynamic visitVarExpr(VarExpr expr);

  /// 类型
  // dynamic visitTypeExpr(TypeExpr expr);

  /// 括号表达式
  dynamic visitGroupExpr(GroupExpr expr);

  /// 赋值表达式，返回右值，执行顺序优先右边
  ///
  /// 因此，a = b = c 解析为 a = (b = c)
  dynamic visitAssignExpr(AssignExpr expr);

  /// 下标取值表达式
  dynamic visitSubGetExpr(SubGetExpr expr);

  /// 下标赋值表达式
  dynamic visitSubSetExpr(SubSetExpr expr);

  /// 属性取值表达式
  dynamic visitMemberGetExpr(MemberGetExpr expr);

  /// 属性赋值表达式
  dynamic visitMemberSetExpr(MemberSetExpr expr);

  /// 函数调用表达式，即便返回值是void的函数仍然还是表达式
  dynamic visitCallExpr(CallExpr expr);

  /// 新建对象表达式
  //dynamic visitNewExpr(NewExpr expr);

  /// This表达式
  dynamic visitThisExpr(ThisExpr expr);
}

abstract class Expr {
  String get type;
  final int lineNumber;
  final int colNumber;

  /// 取表达式右值，返回值本身
  dynamic accept(ExprVisitor visitor);

  Expr(this.lineNumber, this.colNumber);
}

class LiteralExpr extends Expr {
  @override
  String get type => Constants.LiteralExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitLiteralExpr(this);

  final Token value;

  LiteralExpr(this.value) : super(value.lineNumber, value.colNumber);
}

//TODO: 数组和字典的字面量

class UnaryExpr extends Expr {
  @override
  String get type => Constants.UnaryExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitUnaryExpr(this);

  /// 各种单目操作符
  final Token op;

  /// 变量名、表达式、函数调用
  final Expr value;

  UnaryExpr(this.op, this.value) : super(op.lineNumber, op.colNumber);
}

class BinaryExpr extends Expr {
  @override
  String get type => Constants.BinaryExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitBinaryExpr(this);

  /// 左值
  final Expr left;

  /// 各种双目操作符
  final Token op;

  /// 变量名、表达式、函数调用
  final Expr right;

  BinaryExpr(this.left, this.op, this.right) : super(op.lineNumber, op.colNumber);
}

class VarExpr extends Expr {
  @override
  String get type => Constants.VarExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitVarExpr(this);

  final Token name;

  VarExpr(this.name) : super(name.lineNumber, name.colNumber);
}

// class TypeExpr extends Expr {
//   @override
//   String get type => HetuTypes.TypeExpr;

//   @override
//   dynamic accept(ExprVisitor visitor) => visitor.visitTypeExpr(this);

//   final Token name;

//   TypeExpr(this.name) : super(name.lineNumber, name.colNumber);
// }

class GroupExpr extends Expr {
  @override
  String get type => Constants.VarExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitGroupExpr(this);

  final Expr expr;

  GroupExpr(this.expr) : super(expr.lineNumber, expr.colNumber);
}

class AssignExpr extends Expr {
  @override
  String get type => Constants.AssignExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitAssignExpr(this);

  /// 变量名
  final Token variable;

  /// 各种赋值符号变体
  final Token op;

  /// 变量名、表达式、函数调用
  final Expr value;

  AssignExpr(this.variable, this.op, this.value) : super(op.lineNumber, op.colNumber);
}

class SubGetExpr extends Expr {
  @override
  String get type => Constants.SubGetExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitSubGetExpr(this);

  /// 数组
  final Token array;

  /// 索引
  final Expr index;

  SubGetExpr(this.array, this.index) : super(array.lineNumber, array.colNumber);
}

class SubSetExpr extends Expr {
  @override
  String get type => Constants.SubSetExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitSubSetExpr(this);

  /// 数组
  final Token array;

  /// 索引
  final Expr index;

  /// 值
  final dynamic value;

  SubSetExpr(this.array, this.index, this.value) : super(array.lineNumber, array.colNumber);
}

class MemberGetExpr extends Expr {
  @override
  String get type => Constants.MemberGetExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitMemberGetExpr(this);

  /// 集合
  final Expr collection;

  /// 属性
  final Token key;

  MemberGetExpr(this.collection, this.key) : super(collection.lineNumber, collection.colNumber);
}

class MemberSetExpr extends Expr {
  @override
  String get type => Constants.MemberSetExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitMemberSetExpr(this);

  /// 集合
  final Expr collection;

  /// 属性
  final Token key;

  /// 值
  final dynamic value;

  MemberSetExpr(this.collection, this.key, this.value) : super(collection.lineNumber, collection.colNumber);
}

class CallExpr extends Expr {
  @override
  String get type => Constants.CallExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitCallExpr(this);

  /// 可能是单独的变量名，也可能是一个表达式作为函数使用
  final Expr callee;

  /// 函数声明的参数是parameter，调用时传入的变量叫argument
  final List<Expr> args;

  CallExpr(this.callee, this.args) : super(callee.lineNumber, callee.colNumber);
}

// class NewExpr extends Expr {
//   @override
//   String get type => HetuTypes.NewExpr;

//   @override
//   dynamic accept(ExprVisitor visitor) => visitor.visitNewExpr(this);

//   final Token name;

//   NewExpr(this.name) : super(name.lineNumber, name.colNumber);
// }

class ThisExpr extends Expr {
  @override
  String get type => Constants.This;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitThisExpr(this);

  final Token keyword;

  ThisExpr(this.keyword) : super(keyword.lineNumber, keyword.colNumber);
}
