# base error for all categroy error's
class CategoryError(Exception):
    pass

class CategoryNameAlreadyTaken(CategoryError):
    pass

class CategoryNotFound(CategoryError):
    pass

class CouldnotDeleteCategory(CategoryError):
    pass