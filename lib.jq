def to_ascii_code: explode[0];
def to_ascii_code($char): $char | to_ascii_code;

def from_ascii_code: [.] | implode;
def from_ascii_code($char): $char | from_ascii_code;

def intersection(set1; set2): set1 - (set1 - set2);

def group_by_key(key_filter): group_by(key_filter) | map({(.[0] | key_filter | tostring): .}) | add;

def zip($that): [., $that] | transpose;
