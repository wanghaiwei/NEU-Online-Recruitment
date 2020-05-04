//历史记录堆栈
const HistoryStack = {
    _history: [], // 历史记录堆栈
    _length: 0,
    push(path) { // 入栈
        this._length = this._history.push(path);
    },
    pop() {
        this._history.pop();
    },
    canBack() {
        return this._history.length > 1;
    },
    top() {
        return this._history[this._length]
    }
};

export default HistoryStack;