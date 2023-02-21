package proxy

import (
	"fmt"
	"net/http"
	"net/http/httputil"
	"net/url"
	"time"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/nginx"
)

var (
	defaultTarget = helper.URLMustParse("http://localhost")
)

type Proxy struct {
	Version                string
	reverseProxy           *httputil.ReverseProxy
	AllowResponseBuffering bool
	customHeaders          map[string]string
	forceTargetHostHeader  bool
}

func WithCustomHeaders(customHeaders map[string]string) func(*Proxy) {
	return func(proxy *Proxy) {
		proxy.customHeaders = customHeaders
	}
}

func WithForcedTargetHostHeader() func(*Proxy) {
	return func(proxy *Proxy) {
		proxy.forceTargetHostHeader = true
	}
}

func NewProxy(myURL *url.URL, version string, roundTripper http.RoundTripper, options ...func(*Proxy)) *Proxy {
	p := Proxy{Version: version, AllowResponseBuffering: true, customHeaders: make(map[string]string)}

	if myURL == nil {
		myURL = defaultTarget
	}

	u := *myURL // Make a copy of p.URL
	u.Path = ""
	p.reverseProxy = httputil.NewSingleHostReverseProxy(&u)
	p.reverseProxy.Transport = roundTripper
	chainDirector(p.reverseProxy, func(r *http.Request) {
		r.Header.Set("Gitlab-Workhorse", p.Version)
		r.Header.Set("Gitlab-Workhorse-Proxy-Start", fmt.Sprintf("%d", time.Now().UnixNano()))

		for k, v := range p.customHeaders {
			r.Header.Set(k, v)
		}
	})

	for _, option := range options {
		option(&p)
	}

	if p.forceTargetHostHeader {
		// because of https://github.com/golang/go/issues/28168, the
		// upstream won't receive the expected Host header unless this
		// is forced in the Director func here
		chainDirector(p.reverseProxy, func(request *http.Request) {
			// send original host along for the upstream
			// to know it's being proxied under a different Host
			// (for redirects and other stuff that depends on this)
			request.Header.Set("X-Forwarded-Host", request.Host)
			request.Header.Set("Forwarded", fmt.Sprintf("host=%s", request.Host))

			// override the Host with the target
			request.Host = request.URL.Host
		})
	}

	return &p
}

func chainDirector(rp *httputil.ReverseProxy, nextDirector func(*http.Request)) {
	previous := rp.Director
	rp.Director = func(r *http.Request) {
		previous(r)
		nextDirector(r)
	}
}

func (p *Proxy) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if p.AllowResponseBuffering {
		nginx.AllowResponseBuffering(w)
	}

	// If the ultimate client disconnects when the response isn't fully written
	// to them yet, httputil.ReverseProxy panics with a net/http.ErrAbortHandler
	// error. We can catch and discard this to keep the error log clean
	defer func() {
		if err := recover(); err != nil {
			if err != http.ErrAbortHandler {
				panic(err)
			}
		}
	}()

	p.reverseProxy.ServeHTTP(w, r)
}
