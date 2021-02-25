// MIT License
//
// Copyright (c) 2020 Plamen Petrov and EASE lab
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

package ctriface

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"testing"
	"time"

	ctrdlog "github.com/containerd/containerd/log"
	"github.com/containerd/containerd/namespaces"
	"github.com/ease-lab/vhive/metrics"
	log "github.com/sirupsen/logrus"
	"github.com/stretchr/testify/require"
)

const (
	benchDir = "bench_results"
)

func TestBenchmarkStart(t *testing.T) {
	log.SetFormatter(&log.TextFormatter{
		TimestampFormat: ctrdlog.RFC3339NanoFixed,
		FullTimestamp:   true,
	})

	log.SetOutput(os.Stdout)

	log.SetLevel(log.InfoLevel)

	testTimeout := 2000 * time.Second
	ctx, cancel := context.WithTimeout(namespaces.WithNamespace(context.Background(), namespaceName), testTimeout)
	defer cancel()

	orch := NewOrchestrator("devmapper", "", WithTestModeOn(true), WithUPF(*isUPFEnabled))

	images := getAllImages()
	benchCount := 10
	vmID := 0

	createResultsDir()

	for funcName, imageName := range images {
		vmIDString := strconv.Itoa(vmID)
		startMetrics := make([]*metrics.Metric, benchCount)

		// Pull image
		_, err := orch.getImage(ctx, imageName)
		require.NoError(t, err, "Failed to pull image "+imageName)

		for i := 0; i < benchCount; i++ {
			dropPageCache()

			_, metric, err := orch.StartVM(ctx, vmIDString, imageName)
			require.NoError(t, err, "Failed to start VM")
			startMetrics[i] = metric

			err = orch.StopSingleVM(ctx, vmIDString)
			require.NoError(t, err, "Failed to stop VM")
		}

		outFileName := "start.txt"
		metrics.PrintMeanStd(getOutFile(outFileName), funcName, startMetrics...)

		vmID++

	}

	orch.Cleanup()
}

func dropPageCache() {
	cmd := exec.Command("sudo", "/bin/sh", "-c", "sync; echo 1 > /proc/sys/vm/drop_caches")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stdout

	if err := cmd.Run(); err != nil {
		log.Fatalf("Failed to drop caches: %v", err)
	}
}

func createResultsDir() {
	if err := os.MkdirAll(benchDir, 0777); err != nil {
		log.Fatalf("Failed to create results dir: %v", err)
	}
}

func getOutFile(name string) string {
	return filepath.Join(benchDir, name)
}

func getAllImages() map[string]string {
	return map[string]string{
		"helloworld":   "vhiveease/helloworld:var_workload",
		"chameleon":    "vhiveease/chameleon:var_workload",
		"pyaes":        "vhiveease/pyaes:var_workload",
		"image_rotate": "vhiveease/image_rotate:var_workload",
		"json_serdes":  "vhiveease/json_serdes:var_workload",
		"lr_serving":   "vhiveease/lr_serving:var_workload",
		"cnn_serving":  "vhiveease/cnn_serving:var_workload",
		"rnn_serving":  "vhiveease/rnn_serving:var_workload",
		"lr_training":  "vhiveease/lr_training:var_workload",
	}
}
