import pickle


def load_pickle(filename):
    return pickle.load(open(filename, "rb"))


def load_weight(filename):
    return pickle.load(open("w_" + filename, "rb"))
