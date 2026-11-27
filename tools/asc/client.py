"""Minimal App Store Connect API client.

Needs ASC_KEY_ID and ASC_ISSUER_ID in the environment and the key file at
~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8. Requires pyjwt[crypto] and requests.
"""
import os, time, json
import jwt, requests

BASE = "https://api.appstoreconnect.apple.com"


class ASCError(Exception):
    pass


class ASC:
    def __init__(self):
        self.key_id = os.environ["ASC_KEY_ID"]
        self.issuer = os.environ["ASC_ISSUER_ID"]
        path = os.path.expanduser(f"~/.appstoreconnect/private_keys/AuthKey_{self.key_id}.p8")
        with open(path) as f:
            self.key = f.read()
        self._token, self._exp = None, 0
        self.s = requests.Session()

    def token(self):
        if time.time() > self._exp - 60:
            self._exp = int(time.time()) + 15 * 60
            self._token = jwt.encode({"iss": self.issuer, "exp": self._exp, "aud": "appstoreconnect-v1"},
                                     self.key, algorithm="ES256", headers={"kid": self.key_id, "typ": "JWT"})
        return self._token

    def req(self, method, path, body=None, params=None, ok=(200, 201, 204)):
        url = path if path.startswith("http") else BASE + path
        for attempt in range(5):
            r = self.s.request(method, url, params=params, json=body,
                               headers={"Authorization": f"Bearer {self.token()}"})
            if r.status_code == 429 or r.status_code >= 500:
                time.sleep(2 * (attempt + 1))
                continue
            break
        if r.status_code not in ok:
            raise ASCError(f"{method} {path} -> {r.status_code}: {r.text[:1500]}")
        return r.json() if r.content else None

    def get(self, path, **params):
        return self.req("GET", path, params=params or None)

    def get_all(self, path, **params):
        params.setdefault("limit", 200)
        out, url = [], path
        while url:
            d = self.req("GET", url, params=params if url == path else None)
            out += d["data"]
            url = d.get("links", {}).get("next")
        return out

    def post(self, path, body):
        return self.req("POST", path, body)

    def patch(self, path, body):
        return self.req("PATCH", path, body)

    def delete(self, path):
        return self.req("DELETE", path)


def dump(x):
    print(json.dumps(x, indent=1, ensure_ascii=False))
