#import "@preview/lilaq:0.5.0" as lq

#set text(font: "New Computer Modern", lang: "vi")
#set page(paper: "a4", margin: 2cm)

= Benchmark cấu trúc dữ liệu cho Leaderboard Realtime

== 1. Phương pháp

Ta đánh giá hiệu năng của 5 cấu trúc dữ liệu (Sorted Array, Linked List, Red-Black Tree, Skip List, Score-Indexed Array) thông qua hai kịch bản kiểm thử:

1. *Micro-benchmark*:
  - Đo thời gian thực thi trung bình của từng thao tác đơn lẻ: *Insert*, *Search*, *Delete*.
    - Thực hiện trên các tập dữ liệu có kích thước tăng dần: 5,000, 10,000, 20,000, 50,000 và 100,000 phần tử.
    - Mục tiêu: Đánh giá chi phí cơ bản của từng thao tác.

2. *Realtime Simulation*:
  - Mô phỏng môi trường thực tế với tải cao (High Churn).
  - *Tỷ lệ Churn*: 30% người dùng cập nhật điểm số mỗi giây (Update = Delete cũ + Insert mới).
  - *Quy mô*: Kiểm thử khả năng chịu tải với 5,000, 10,000, 20,000, 50,000 và 100,000 phần tử.
  - *Tiêu chí*: Đo độ trễ (latency) của thao tác Update và Search. Hệ thống được coi là "quá tải" (Falling Behind) nếu thời gian xử lý batch 1 giây vượt quá 1 giây thực tế.

== 2. Kết quả thực nghiệm

=== 2.1. Micro-benchmark (Độ trễ thao tác đơn lẻ)

Biểu đồ dưới đây thể hiện sự thay đổi thời gian thực thi (Average Latency) theo kích thước dữ liệu (Batch Size).

#let raw_data = csv("benchmark_results.csv")
#let rows = raw_data.slice(1)

#let algos = (
  "SortedArrayLeaderboard",
  "LinkedListLeaderboard",
  "RBTreeLeaderboard",
  "SkipListLeaderboard",
  "ScoreIndexedArrayLeaderboard",
)
#let algo_labels = ("Array", "LinkedList", "RBTree", "SkipList", "ScoreIndexed")
#let marks = ("o", "s", "^", "x", "*")
#let colors = (blue, green, red, purple, orange)

#let get_data(algo, col_index) = {
  rows.filter(r => r.at(0) == algo).map(r => (int(r.at(1)), float(r.at(col_index))))
}

#let plot_op(col_index, title_text, y_label) = {
  lq.diagram(
    title: title_text,
    xlabel: "Batch Size",
    ylabel: y_label,
    legend: (position: (100% + .5em, 0%)),
    ..algos
      .enumerate()
      .map(((i, algo)) => lq.plot(
        get_data(algo, col_index).map(x => x.at(0)),
        get_data(algo, col_index).map(x => x.at(1)),
        label: algo_labels.at(i),
        mark: marks.at(i),
        color: colors.at(i),
      )),
  )
}

#figure(
  plot_op(3, "Insert Latency vs Batch Size", "Time (us)"),
  caption: [Insert Latency (Average)],
)

#figure(
  plot_op(5, "Search Latency vs Batch Size", "Time (us)"),
  caption: [Search Latency (Average)],
)

#figure(
  plot_op(7, "Delete Latency vs Batch Size", "Time (us)"),
  caption: [Delete Latency (Average)],
)

=== 2.2. Realtime Simulation (Độ trễ dưới tải cao)

Mô phỏng tải thực tế với 30% user cập nhật điểm số mỗi giây.

#let rt_raw_data = csv("realtime_benchmark_results.csv")
#let rt_rows = rt_raw_data.slice(1)

#let rt_algos = ("SortedArrayLeaderboard", "RBTreeLeaderboard", "SkipListLeaderboard", "ScoreIndexedArrayLeaderboard")
#let rt_labels = ("Array", "RBTree", "SkipList", "ScoreIndexed")
#let rt_indices = (0, 2, 3, 4)

#let get_rt_data(algo, col_index) = {
  rt_rows.filter(r => r.at(0) == algo).map(r => (int(r.at(1)), float(r.at(col_index))))
}

#let plot_rt_op(col_index, title_text, y_label) = {
  lq.diagram(
    title: title_text,
    xlabel: "Dataset Size",
    ylabel: y_label,
    legend: (position: (100% + .5em, 0%)),
    ..rt_algos
      .enumerate()
      .map(((i, algo)) => lq.plot(
        get_rt_data(algo, col_index).map(x => x.at(0)),
        get_rt_data(algo, col_index).map(x => x.at(1)),
        label: rt_labels.at(i),
        mark: marks.at(rt_indices.at(i)),
        color: colors.at(rt_indices.at(i)),
      )),
  )
}

#figure(
  plot_rt_op(3, "Realtime Update Latency", "Time (us)"),
  caption: [Update Latency under Load],
)

#figure(
  plot_rt_op(5, "Realtime Search Latency", "Time (us)"),
  caption: [Search Latency under Load],
)

== 3. Nhận xét và So sánh

=== 3.1. Phân tích chi tiết

- *Sorted Array*: Rất nhanh ở các thao tác đọc (Search) nhờ Binary Search. Tuy nhiên, thao tác ghi (Insert/Delete/Update) cực chậm ($O(N)$) khi dữ liệu lớn. Trong kịch bản Realtime, nó bắt đầu quá tải khi dữ liệu đạt 100k phần tử.
- *Linked List*: Hiệu năng kém nhất ($O(N)$ cho mọi thao tác). Không vượt qua được bài test Realtime ngay cả ở mức 10k phần tử.
- *Red-Black Tree*: Cấu trúc ổn định nhất. Đảm bảo hiệu năng $O(log N)$ cho mọi thao tác, chịu tải tốt ở mức 100k phần tử.
- *Skip List*: Hiệu năng tương đương Red-Black Tree, là một sự thay thế tốt với cài đặt có phần đơn giản hơn về mặt ý tưởng (dù tốn bộ nhớ hơn).
- *Score-Indexed Array*: Sử dụng mảng 15k phần tử, mỗi phần tử lưu danh sách ID người chơi có điểm tương ứng. Insert/Update cực nhanh ($O(1)$), nhưng Search rank chậm ($O("max_score")$). Phù hợp khi có ràng buộc điểm số và ưu tiên thao tác ghi.

=== 3.2. Bảng so sánh tổng hợp

#table(
  columns: (auto, auto, auto, auto, auto),
  inset: 10pt,
  align: horizon,
  fill: (col, row) => if row == 0 { gray.lighten(50%) } else { none },
  [*Thuật toán*],
  [*Độ phức tạp* \ (Search/Update)],
  [*Micro-bench* \ (Read/Write)],
  [*Realtime* \ (Scalability)],
  [*Đánh giá*],

  [Sorted Array], [$O(log n)$ / $O(n)$], [Rất Tốt / Kém], [Kém \ (Fail @ 100k)], [Tốt cho ít ghi],
  [Linked List], [$O(n)$ / $O(n)$], [Kém / Kém], [Rất Kém \ (Fail @ 10k)], [Không phù hợp],
  [RB Tree], [$O(log n)$ / $O(log n)$], [Tốt / Tốt], [Tốt \ (Pass @ 100k)], [Khuyên dùng],
  [Skip List], [$O(log n)$ / $O(log n)$], [Tốt / Tốt], [Tốt \ (Pass @ 100k)], [Thay thế tốt],
  [Score-Indexed], [$O("max")$ / $O(1)$], [Chậm / Rất Tốt], [Tốt \ (Pass @ 100k)], [Tốt cho nhiều ghi],
)
