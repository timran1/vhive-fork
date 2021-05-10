module github.com/ease-lab/vhive/ctriface

go 1.15

// Workaround for github.com/containerd/containerd issue #3031
replace github.com/docker/distribution v2.7.1+incompatible => github.com/docker/distribution v2.7.1-0.20190205005809-0d3efadf0154+incompatible

replace (
	github.com/firecracker-microvm/firecracker-containerd => github.com/ease-lab/firecracker-containerd v0.0.0-20200804113524-bc259c9e8152
	github.com/firecracker-microvm/firecracker-go-sdk => github.com/ease-lab/firecracker-go-sdk v0.20.1-0.20200625102438-8edf287b0123
)

replace (
	github.com/ease-lab/vhive/memory/manager => ../memory/manager
	github.com/ease-lab/vhive/metrics => ../metrics
	github.com/ease-lab/vhive/misc => ../misc
	github.com/ease-lab/vhive/taps => ../taps
)

require (
	github.com/containerd/containerd v1.5.0
	github.com/davecgh/go-spew v1.1.1
	github.com/ease-lab/vhive/memory/manager v0.0.0-00010101000000-000000000000
	github.com/ease-lab/vhive/metrics v0.0.0-00010101000000-000000000000
	github.com/ease-lab/vhive/misc v0.0.0-00010101000000-000000000000
	github.com/firecracker-microvm/firecracker-containerd v0.0.0-00010101000000-000000000000
	github.com/go-multierror/multierror v1.0.2
	github.com/pkg/errors v0.9.1
	github.com/sirupsen/logrus v1.8.0
	github.com/stretchr/testify v1.7.0
	google.golang.org/grpc v1.33.2

)
