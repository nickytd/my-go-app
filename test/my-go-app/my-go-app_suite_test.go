package logging_test

import (
	"testing"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

// testID is used to group tests belonging to the gardener logging components
const testID = "my-go-app"

func TestLogging(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, testID+" Suite")
}
