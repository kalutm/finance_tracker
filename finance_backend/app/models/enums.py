from enum import Enum

class Provider(str, Enum):
    LOCAL = "LOCAL"
    GOOGLE = "GOOGLE"
    LOCAL_GOOGLE = "LOCAL_GOOGLE"
