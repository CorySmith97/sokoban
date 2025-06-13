package main

//
// UNDO TREE
//
// The undo tree is a backwards tree. IE the front of
// the linked list is the most recent move. When we remove, we always remove from the
// front.
//

Node :: struct {
    next: ^Node,
    state: Scene,
}

Undo_Tree :: struct {
    start: ^Node,
}

undo_tree_add :: proc(tree: ^Undo_Tree, n: ^Node) {
    n.next = tree.start
    tree.start = n
}

undo_tree_front_remove :: proc(tree: ^Undo_Tree) {

}
