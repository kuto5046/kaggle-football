# Google Research Football with Manchester City F.C.

![](./img/001.png "football game display")
competition link is [here](https://www.kaggle.com/c/google-football)

---

## Rules
### 基本ルール
11人チームの1人のプレイヤーを操作可能  
ルールは公式のサッカーとほとんど同じ(オフサイド、イエローカード、レッドカード)  
しかし僅かながら違いがある

- ゲームは2つのハーフ、45分（1500 steps）ずつで構成。(つまり1step=1.8s)
各ハーフの開始時のキックオフは別のチームで行われるが、サイドの入れ替えはなし（ゲームは完全に左右対称です）。
- 各エージェントは、チーム内の1人の選手をコントロール。コントロールされたプレイヤーは、**常にボールを持っているプレイヤー、または守備時にボールに近いプレイヤーとなる。**
- ゲーム中にチームがサイドを入れ替えることはない。左右のサイドはランダムに割り当てられる。
- エージェント実装の便宜上，提供されるオブザベーションは，**エージェントが左チームをコントロールしているかのように常に表示される**．
- 環境は、観察とアクションの両方に適切な変換を適用する。ゲームエンジンは完全に対称的であるため、左右の入れ替えはゲームに影響を与えない。
- 非カップスコアリングルールが適用され、より多くのゴールを決めたチームが勝ち。
- チームの選手数が7人以下になった場合、ウォークオーバーは適用されません。
- 交代選手は存在しない。
- 延長戦は適用されない。

### オブザベーションと行動
各ターンで、エージェントは現在のスコア、全プレイヤーの位置、プレイヤーのスピード、疲労度を含むゲームの完全な状態を表すオブザベーションを受け取る。
オブザベーションの詳細なフォーマットは[こちら](https://github.com/google-research/football/blob/master/gfootball/doc/observation.md#raw-observations)  
各ターンで、エージェントはデフォルトのアクションセットから19のアクション（0から18までの番号）のうちの1つを生成する。
アクションセットの外のアクションを返すとエージェントの損失となる。[(参考)](https://github.com/google-research/football/blob/master/gfootball/doc/observation.md#default-action-set)


### ゲーム終了
3000ターン後、またはエージェントのどちらかがエラーを起こした場合(タイムアウト、例外が投げられた場合、無効なアクションが返された場合)にゲーム終了。
エラーを起こしたエージェントが負け、他のエージェントが勝つ。エラーがなかった場合は、より多くのゴールを獲得したチームが勝ち。
ランキングは評価ルールに従って更新。

---

## citation 
[1][Google Research Footballに関する論文](http://arxiv.org/abs/1907.11180)  
[2][SEED RL](https://arxiv.org/abs/1910.06591)
    強化学習手法のベースラインとしてはじめに与えられている手法。
    Google Research FootballでSOTA

[3]PFRL(PyTorchの強化学習フレームワーク)
[GitHub](https://github.com/pfnet/pfrl), [docment](http://pfrl.readthedocs.io/en/latest/index.html)
[4][公式紹介のブログ記事](https://sites.google.com/view/rl-football/singleagent-team)

---

## log

### [2020/09/30]
discussionにGRF論文の内容を投稿　
https://www.kaggle.com/c/google-football/discussion/187657

[公式からのdiscussion](https://www.kaggle.com/c/google-football/discussion/187381)より
- validation episodeが75分ととても長いこと
- windows上では環境がうまく動かないこと
- ごくたまにvalidation episodeが終了しないことがある
- 新しいepisodesが処理されない

アイデア　CNNに入力する際に次元数を増やしSMMをpixel入力に重ねて入力

やったこと
- googlefootのAPIを触る
- ２つ目のSEED RLをsubして強化学習の様子を見る
- ファイルのoutput形式がtz形式


### [2020/10/01]
SEED RL[2]の論文を読んだ。
<!--- <div align="center"><img src="./img/002.jpg" width=500 title="SEED-RL Table 1"></div>-->

<div align="center"><img src="./img/003.jpg" width=400 title="SEED-RL Table 2"></div>

<!-- <div align="center"><img src="./img/004.jpg" width=500 title="SEED-RL Table 5"></div>  -->
  
   
- TPUによって計算コストをかなり抑えられる一方p100だとあまり向上しない
- 計算効率は高いのでSEED RLをベースに学習アルゴリズムや報酬をを変更する方針で進める
- TPU v3を32コア使うとmax(1試行？)がscoring rewardで4.76(4点相当), checkpointでが7.66とかなり大きい.
しかし上記は計算機がないので流石に実現不可(4億フレーム学習と書いている、意味がわからない)
- フレーム数を極端に大きく取らない限りSMM(super mini map)のimage sizeを大きくしても変化はないみたい
- SEED RLのSMM defaultで$345(4万くらい?)

ブログ記事[4]を読んだ
本ゲーム環境は３種類の表現がある
- Pixels表現は自然に見えるが、ノイズが多く、表現サイズが膨大なために失敗
- Super MiniMapとSimple115は同等の表現であるが、Simple115の方が環境に関するデータ量が多い。
- 論文では, Super MiniMap > Floats(Simple115)
- この結果を直感的ではないものと考え,"Floats "表現を使用する強力なエージェントの作成を試みる。

<div align="center"><img src="./img/005.png" title="result PPO"></div>
easy modeはうまくいっているが,hard modeはおもわしくない。easy modeのみではオーバーフィットしてしまう(hard modeに対応できない)  

そこで**平均報酬が選択されたしきい値に達すると、次のラウンドから難易度をイプシロン増加させる**
<div align="center"><img src="./img/006.png" width=500 title="result ε scheduling"></div>

- 良い効果が出ている
- ただし800Mステップに15日かかる  
- 計算効率を改善するために32 CPUs(instead of 16), 64 parallel environments(instead of 16) 
- **CHECKPOINT報酬は初めに適用させゴールが決まるようになったら減衰させ0に近づけていくのがおすすめ**
