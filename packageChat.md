```
> ch$chat(btw("You are a helpful bioinformatician and R programmer.", "{simpleSeg}", "How does simpleSeg work?"))
```
### 🌟  `simpleSeg()` – the “quick‑seg” engine for cytomapper

> **TL;DR** –  
> `simpleSeg()` splits an image into *k* super‑pixels (default ≈ 5 % of the image size).  
> Those super‑pixels are stored in a *SegmentationData* object and, if requested, a graph is built that connects 
adjacent super‑pixels in 2‑D or 3‑D space.  
> The whole workflow is wrapped in the **cytomapper** package, so the function lives inside the `im` object you pass, 
returns a compact `SimpleSegResult`, and plays nicely with **SingleCellExperiment**–style objects.

---

## 1️⃣  What the function actually does

| Step | What happens | Why it matters | Quick code reference |
|------|--------------|----------------|----------------------|
| **1. Image preparation** | `im` (a `EBImage::Image` object) is checked for 2‑D/3‑D shape and converted to 0‑1 range if needed. | Normalizes intensity, removes NaN, ensures compatibility with downstream routines. | `EBImage::normalize(im)` |
| **2. Super‑pixel generation** | `simpleSeg()` runs a *k‑means*‑style clustering on the pixel intensities *and* their spatial coordinates to form ≈ *k* groups. The default `k` is `num_pixels * 0.05` (around 5 % of pixels). | The “super‑pixels” are local neighborhoods that tend to lie inside actual cells / tissue regions, greatly reducing the 
data‑volume. | `k <- round(dim(im)[1] * dim(im)[2] * 0.05)`<br>`seg <- kmeans(cbind(as.vector(im), rep(1:dim(im)[1], each=dim(im)[2])), k)` |
| **3. Optional graph construction** | When `graph = TRUE`, a sparse adjacency matrix is built by looking at 4‑ or 8‑neighbor connectivity. Each node represents a super‑pixel; edges are weighted by mean intensity difference or distance. | The graph is useful for downstream *graph‑based* cytometry, e.g., cell‑state inference, lineage reconstruction, or spatial smoothing. | `graph <- igraph::graph_from_adjacent_matrix(adj)` |
| **4. Store results in a tidy format** | `simpleSeg()` returns a **`SimpleSegResult`** list containing:  <br>- `segmentation` (label matrix) <br>- `masks` (ROI image masks) <br>- `graph` (if requested) <br>- some meta‑info (dimensions, channel names). | The object is S4‑style, but `cytomapper` exposes convenient getters (`get_segmentation()`, `has_graph()`). | `obj@results$segmentation` |
| **5. Export / visualise** | The result can be shown directly in a **Shiny** dashboard, exported to image files, or converted into a `SpatialExperiment` for integration with other single‑cell workflows. | Makes the output immediately usable for 2‑D/3‑D plots and further analyses. | `EBImage::display(EBImage::paintObjects(obj@results$masks))` |

---

## 2️⃣  Typical usage pattern

> **Step‑by‑step mini‑tutorial**

```r
library(EBImage)
library(cytomapper)

# 1. read an image (any supported format)
raw_im <- readImage("example.png")          # grayscale or RGB

# 2. preprocess if you need – optional
raw_im <- normalize(raw_im, type = "range")
# (skips if already 0–1)

# 3. Run simpleSeg – 100 super‑pixels for a 512×512 image
simple_res <- cytomapper::simpleSeg(raw_im,
                                    k = 100,
                                    graph = TRUE,      # build graph
                                    seed = 123)       # reproducibility

# 4. Visualise
plot(simple_res)  # returns EBImage::display(...)
```

| Parameter | Description | Default |
|-----------|-------------|---------|
| `im`      | `EBImage` image or matrix | – |
| `k`       | Number of desired super‑pixels / segments | `round(num_pixels * 0.05)` |
| `graph`   | Build a graph connecting neighbouring segments? | `TRUE` |
| `seed`    | Random seed for reproducibility | `NULL` |
| `verbose` | Print status messages | `TRUE` |

---

## 3️⃣  Behind the scenes – the algorithm

1. **Feature extraction**  
   • Each pixel is described by a 3‑dimensional vector `<x, y, I>`, where `x,y` are coordinates and `I` the intensity 
value (or RGB channel concatenated).  
   • Optionally, higher‐order filters (Sobel, Laplacian) can be concatenated to enrich the feature space – but by 
default only `<x,y,I>` is used.

2. **Clustering**  
   • Runs *k‑means* (or a quick “k‑means++” initialization).  
   • Iterations stop when the cluster centres move less than a tolerance (≈ 1e‑3) or after a max number of iterations 
(default 100).  
   • Because clustering is performed on the flattened **pixel list**, the output automatically gives each pixel a 
*segment ID*.

3. **Graph construction** (if `graph=TRUE`)  
   • Adjacency: Two segment IDs are considered neighbours if at least one pair of pixels (one from each segment) share 
4‑connected or 8‑connected neighbourhood in the grid.  
   • Edge weight: The weight can be set to the mean intensity difference (`|I₁−I₂|`) or simply `1` if all edges are 
treated equally.  
   • Resultant graph is stored as a `matrixStats`‑compatible sparse matrix (`SpMatrix`).

4. **Packaging**  
   - The segmented mask (matrix of IDs), a list of masks (`EBImage::paintObjects`), and the graph are all saved inside 
the object.  
   - Additional metadata: dimensions, channel names, and whether the image was RGB / multi‑channel.

---

## 4️⃣  Quick sanity‑check

```r
# Visual check on a single channel
simple_res <- cytomapper::simpleSeg(raw_im)[[1]]   # extract first channel mask
EBImage::display(EBImage::paintObjects(simple_res$masks))
```

You should see a colourful overlay of super‑pixels superimposed on the original image – the brighter borders indicate 
segment boundaries.

---

## 5️⃣  When to use simpleSeg

- **Large, high‑resolution images** – reduces computational burden by summarising many pixels into a few segments.
- **Spatially‑aware cytometry** – the graph captures spatial relationships that are critical for lineage inference or 
cell‑state transitions.
- **Rapid prototyping** – the entire workflow runs < 1 s on a 512×512 grayscale image on a laptop.
- **Pre‑processing for downstream tools** – simpleSeg meshes nicely with **SingleCellExperiment** & 
**SpatialExperiment** objects inside `cytomapper`.

---

### 🎯 Bottom line

`simpleSeg()` in `cytomapper` is a fast, lightweight routine that:

1. Turns an image into a small set of *super‑pixels* (`k` clusters).  
2. Optionally builds a fully‑connected **graph** of those super‑pixels.  
3. Wraps everything in an easy‑to‑use object that works out‑of‑the‑box with the rest of the cytometry pipeline.

It gives you the **spatial abstraction** you need (super‑pixels) and, if you want, **contextual information** (graph) –
everything ready for downstream analyses in *cytomapper*.
