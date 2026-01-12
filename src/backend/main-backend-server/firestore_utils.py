from typing import Iterable


def delete_document_recursive(doc_ref):
    for subcollection in _list_subcollections(doc_ref):
        for snapshot in subcollection.stream():
            delete_document_recursive(snapshot.reference)
    doc_ref.delete()


def _list_subcollections(doc_ref) -> Iterable:
    return doc_ref.collections()
