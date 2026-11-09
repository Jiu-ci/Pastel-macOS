package assets

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"
)

type panghuTransport func(*http.Request) (*http.Response, error)

func (f panghuTransport) RoundTrip(request *http.Request) (*http.Response, error) {
	return f(request)
}

func panghuRangeResponse(status int, contentRange, body string) *http.Response {
	return &http.Response{
		StatusCode: status, Status: fmt.Sprintf("%d %s", status, http.StatusText(status)),
		Header: http.Header{"Content-Range": []string{contentRange}},
		Body:   io.NopCloser(strings.NewReader(body)),
	}
}

func TestPanghuAssetRequestsAvoidDefaultAgent403(t *testing.T) {
	var ranges []string
	client := &http.Client{Transport: panghuTransport(func(request *http.Request) (*http.Response, error) {
		if request.URL.String() != macOSRestoreURL {
			t.Fatalf("unexpected asset URL: %s", request.URL)
		}
		if request.UserAgent() != "panghu/1.0" {
			return panghuRangeResponse(http.StatusForbidden, "", "Forbidden"), nil
		}
		value := request.Header.Get("Range")
		ranges = append(ranges, value)
		switch value {
		case "bytes=0-0":
			return panghuRangeResponse(http.StatusPartialContent, "bytes 0-0/16", "P"), nil
		case "bytes=4-7":
			return panghuRangeResponse(http.StatusPartialContent, "bytes 4-7/16", "abcd"), nil
		default:
			t.Fatalf("unexpected byte range: %s", value)
			return nil, nil
		}
	})}
	remote, err := openRemoteFile(context.Background(), client)
	if err != nil {
		t.Fatal(err)
	}
	data := make([]byte, 4)
	if count, err := remote.ReadAt(data, 4); err != nil || count != 4 || string(data) != "abcd" {
		t.Fatalf("range read: count=%d, body=%q, error=%v", count, data, err)
	}
	if len(ranges) != 2 {
		t.Fatalf("expected probe and subsequent range, got %v", ranges)
	}
}

func TestPanghuAssetRequestsStillRejectInvalidRanges(t *testing.T) {
	for _, value := range []string{"", "bytes 1-1/16", "bytes 0-0/*"} {
		client := &http.Client{Transport: panghuTransport(func(*http.Request) (*http.Response, error) {
			return panghuRangeResponse(http.StatusPartialContent, value, "P"), nil
		})}
		if _, err := openRemoteFile(context.Background(), client); err == nil {
			t.Fatalf("accepted invalid Content-Range %q", value)
		}
	}
	client := &http.Client{Transport: panghuTransport(func(*http.Request) (*http.Response, error) {
		return panghuRangeResponse(http.StatusPartialContent, "bytes 3-6/16", "abcd"), nil
	})}
	remote := &remoteFile{ctx: context.Background(), client: client, url: macOSRestoreURL, size: 16}
	if _, err := remote.ReadAt(make([]byte, 4), 4); err == nil {
		t.Fatal("accepted wrong response range")
	}
}

// Explicit online check prepares the pinned public resources needed for
// authentication (using a verified cache if available), without an Apple account.
func TestPanghuLiveAssets(t *testing.T) {
	if os.Getenv("PASTEL_TEST_APPLE_ASSETS") != "1" {
		t.Skip("set PASTEL_TEST_APPLE_ASSETS=1 to verify public Apple resources online")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()
	started := time.Now()
	if _, err := Load(ctx); err != nil {
		t.Fatal(err)
	}
	t.Logf("All pinned Apple authentication assets prepared and verified in %s", time.Since(started))
}
