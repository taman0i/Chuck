/* through-zero flanger */

//入力ファイルを読み込む
SndBuf input => Gain dry => Gain mixer;
input.read("input.wav");   //入力ファイル
input.loop(0);  //ループ再生無効
input.gain(0.5);    //入力ゲイン

//サンプル数の取得
int totalSamples;
input.samples() => totalSamples;    //サンプル数を変数に代入

//ディレイ
Delay fixedDelay => Gain wet => mixer;
fixedDelay.max(420::samp);  //最大ディレイタイム
fixedDelay.delay(210::samp);    //固定ディレイタイム(最大ディレイタイム*1/2。基準となる)

SndBuf lfo => blackhole;
lfo.read("a.wav");    //ディレイタイム変調用のファイル
lfo.loop(1);    //ループ再生を有効化

//可変ディレイとフィードバック
Gain delayInput => Delay variableDelay => Gain invert => wet;
variableDelay.max(420::samp);   //最大ディレイタイム
invert.gain(-1.0);  //位相を反転

variableDelay => Gain feedback => delayInput;   //フィードバック
feedback.gain(0.5);   //フィードバックゲインの初期値

SndBuf feedbackLFO => blackhole;
feedbackLFO.read("b.wav");    //フィードバックゲイン変調用のファイル
feedbackLFO.loop(1);    //ループ再生有効

//信号接続をループ外で一度だけ行う
input => fixedDelay;    //固定ディレイに接続
input => delayInput;    //可変ディレイの入力に接続

//ゲイン調整
dry.gain(0.0);  // 原音を絞り切る
wet.gain(0.5);  // ウェット(みなしドライ+ウェット)
mixer.gain(1);
mixer => dac;   //出力

int samplePos;  //サンプル位置を追跡

//処理ループ
while (samplePos < totalSamples) {
    //ディレイタイムをwavファイルで更新
    210::samp + (lfo.last() * 210::samp) => variableDelay.delay;    //最大ディレイタイム0～420サンプル(wavファイルが-1～1の値をとることを想定しています)
    
    //フィードバックゲインをwavファイルで変調
    0.25 +(feedbackLFO.last() * 0.25) => feedback.gain;   //フィードバックゲイン0～0.5(wavファイルが-1～1の値をとることを想定しています)
    
    //1サンプル進める
    1::samp => now;
    
    //サンプル位置を更新
    samplePos++;
}

